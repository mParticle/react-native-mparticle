import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

type ColorMode = string;

type CacheConfig = {
    readonly cacheDurationInSeconds?: number;
    readonly cacheAttributes?: { [key: string]: string };
};

type RoktConfigType = {
    readonly colorMode?: ColorMode;
    readonly cacheConfig?: CacheConfig;
};

export interface Spec extends TurboModule {
    selectPlacements(
        identifier: string,
        attributes?: {[key: string]: string},
        placeholders?: {[key: string]: number | null},
        roktConfig?: RoktConfigType,
        fontFilesMap?: {[key: string]: string}
    ): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MPRokt');
