# Tests how ios/mparticle_spm.rb links the mParticle Swift packages into an app's .xcodeproj.
# Run from sample/, which has the CocoaPods Gemfile: bundle exec ruby ../scripts/ios/mparticle_spm_test.rb
require 'cocoapods'
require 'minitest/autorun'
require 'tmpdir'
require_relative '../../ios/mparticle_spm'

class MParticleSPMTest < Minitest::Test
  Installer = Struct.new(:aggregate_targets)
  Aggregate = Struct.new(:platform, :pod_targets, :user_targets, :user_project)
  Platform = Struct.new(:name)
  PodTarget = Struct.new(:pod_name)

  CORE = [MParticleSPM::CORE_URL, MParticleSPM::CORE_PRODUCT].freeze
  ROKT = [MParticleSPM::KITS['mParticle-Rokt']['url'], 'mParticle-Rokt'].freeze
  BRAZE_14 = [MParticleSPM::KITS['mParticle-Braze-14']['url'], 'mParticle-Braze'].freeze
  BRAZE_17 = [MParticleSPM::KITS['mParticle-Braze-17']['url'], 'mParticle-Braze'].freeze
  HAND_ADDED = ['https://github.com/example/other-package', 'Other'].freeze
  FORK = ['https://github.com/example/rokt-kit-fork', 'mParticle-Rokt'].freeze

  def setup
    Pod::Config.instance.silent = true
    @dir = Dir.mktmpdir
    @path = File.join(@dir, 'App.xcodeproj')
    project = Xcodeproj::Project.new(@path)
    project.new_target(:application, 'App', :ios)
    # An app target that does not use react-native-mparticle.
    project.new_target(:application, 'Other', :ios)
    project.save
  end

  def teardown
    FileUtils.remove_entry(@dir)
    $RNMParticleSPMKits = nil
  end

  # Runs the helper as `pod install` would, then reopens the saved project.
  def install(kits)
    $RNMParticleSPMKits = kits
    project = Xcodeproj::Project.open(@path)
    app = project.targets.find { |target| target.name == 'App' }
    aggregate = Aggregate.new(Platform.new(:ios), [PodTarget.new('react-native-mparticle')], [app], project)
    MParticleSPM.link_packages(Installer.new([aggregate]))
    Xcodeproj::Project.open(@path)
  end

  def link_by_hand(target_name, (url, product))
    project = Xcodeproj::Project.open(@path)
    target = project.targets.find { |t| t.name == target_name }
    MParticleSPM.add_package(project, target, url: url, product: product, version: '1.0.0')
    project.save
  end

  def linked(project, target_name)
    target = project.targets.find { |t| t.name == target_name }
    deps = target.package_product_dependencies.map { |dep| [dep.package.repositoryURL, dep.product_name] }
    frameworks = target.frameworks_build_phase.files.map(&:product_ref).compact.map(&:product_name)
    assert_equal deps.map(&:last).sort, frameworks.sort, 'each linked product has one framework build file'
    deps.sort
  end

  def references(project)
    project.root_object.package_references.map(&:repositoryURL).sort
  end

  def pbxproj
    File.read(File.join(@path, 'project.pbxproj'))
  end

  def test_installing_again_changes_nothing
    install(['mParticle-Rokt'])
    before = pbxproj
    project = install(['mParticle-Rokt'])
    assert_equal before, pbxproj
    assert_equal [CORE, ROKT].sort, linked(project, 'App')
  end

  def test_removing_a_kit_unlinks_it
    install(['mParticle-Rokt'])
    project = install([])
    assert_equal [CORE], linked(project, 'App')
    assert_equal [CORE.first], references(project)

    before = pbxproj
    install([])
    assert_equal before, pbxproj
  end

  def test_switching_a_kit_to_another_repository_relinks_its_product
    install(['mParticle-Braze-14'])
    project = install(['mParticle-Braze-17'])
    assert_equal [CORE, BRAZE_17].sort, linked(project, 'App')
    assert_equal [CORE.first, BRAZE_17.first].sort, references(project)

    before = pbxproj
    install(['mParticle-Braze-17'])
    assert_equal before, pbxproj
  end

  def test_keeps_hand_added_packages_and_references_other_targets_use
    link_by_hand('App', HAND_ADDED)
    link_by_hand('Other', ROKT)
    install(['mParticle-Rokt'])
    project = install([])
    assert_equal [CORE, HAND_ADDED].sort, linked(project, 'App')
    assert_equal [ROKT], linked(project, 'Other')
    assert_equal [CORE.first, ROKT.first, HAND_ADDED.first].sort, references(project)
  end

  def test_stops_instead_of_replacing_a_hand_added_package_with_the_same_product
    link_by_hand('App', FORK)
    before = pbxproj
    error = assert_raises(Pod::Informative) { install(['mParticle-Rokt']) }
    assert_includes error.message, FORK.first
    assert_equal before, pbxproj
  end

  def test_a_kit_listed_twice_is_linked_once
    $RNMParticleSPMKits = ['mParticle-Rokt', 'mParticle-Rokt']
    assert_equal 1, MParticleSPM.kits.size
  end

  def test_kits_with_the_same_product_are_rejected
    $RNMParticleSPMKits = ['mParticle-Braze-14', 'mParticle-Braze-17']
    error = assert_raises(Pod::Informative) { MParticleSPM.kits }
    assert_includes error.message, 'mParticle-Braze'
  end
end
