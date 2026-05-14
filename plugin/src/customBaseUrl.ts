export interface CustomBaseUrlProps {
  customBaseUrl?: string;
}

export function getCustomBaseUrl(props: CustomBaseUrlProps): string | null {
  const customBaseUrl = props.customBaseUrl?.trim();

  if (!customBaseUrl) {
    return null;
  }

  let parsedCustomBaseUrl: URL;
  try {
    parsedCustomBaseUrl = new URL(customBaseUrl);
  } catch {
    throw new Error(
      'react-native-mparticle customBaseUrl must be a valid https URL'
    );
  }

  if (
    parsedCustomBaseUrl.protocol !== 'https:' ||
    !parsedCustomBaseUrl.hostname
  ) {
    throw new Error(
      'react-native-mparticle customBaseUrl must be a valid https URL'
    );
  }

  return customBaseUrl;
}
