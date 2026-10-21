import AsyncStorage from '@react-native-async-storage/async-storage';

const WARNING_DISABLED_KEY = 'clashking:game-handoff-warning-disabled';

export async function shouldShowGameHandoffWarning(): Promise<boolean> {
  try {
    return (await AsyncStorage.getItem(WARNING_DISABLED_KEY)) !== 'true';
  } catch {
    return true;
  }
}

export async function disableGameHandoffWarning(): Promise<void> {
  await AsyncStorage.setItem(WARNING_DISABLED_KEY, 'true');
}
