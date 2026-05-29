import React from 'react';
import {StatusBar} from 'expo-status-bar';
import {NavigationContainer, DarkTheme} from '@react-navigation/native';
import {createNativeStackNavigator} from '@react-navigation/native-stack';
import {SafeAreaProvider} from 'react-native-safe-area-context';
import {GestureHandlerRootView} from 'react-native-gesture-handler';

import HomeScreen from './src/screens/HomeScreen';
import VoiceSelectScreen from './src/screens/VoiceSelectScreen';
import ProgressScreen from './src/screens/ProgressScreen';
import ResultScreen from './src/screens/ResultScreen';

export type RootStackParamList = {
  Home: undefined;
  VoiceSelect: {
    isUrl: boolean;
    url?: string;
    filePath?: string;
    fileName?: string;
    mimeType?: string;
  };
  Progress: {
    isUrl: boolean;
    url?: string;
    filePath?: string;
    mimeType?: string;
    character: string;
  };
  Result: {jobId: string};
};

const Stack = createNativeStackNavigator<RootStackParamList>();

const navTheme = {
  ...DarkTheme,
  colors: {
    ...DarkTheme.colors,
    background: '#0D0F1A',
    card: '#0D0F1A',
    primary: '#7C6AFF',
    text: '#FFFFFF',
    border: 'transparent',
    notification: '#FF6AAD',
  },
};

export default function App() {
  return (
    <GestureHandlerRootView style={{flex: 1, backgroundColor: '#0D0F1A'}}>
      <SafeAreaProvider>
        <StatusBar style="light" />
        <NavigationContainer theme={navTheme}>
          <Stack.Navigator
            initialRouteName="Home"
            screenOptions={{
              headerStyle: {backgroundColor: '#0D0F1A'},
              headerTintColor: '#FFFFFF',
              headerTitleStyle: {fontWeight: '700'},
              contentStyle: {backgroundColor: '#0D0F1A'},
            }}>
            <Stack.Screen
              name="Home"
              component={HomeScreen}
              options={{title: '🎙️ VideoDub AI'}}
            />
            <Stack.Screen
              name="VoiceSelect"
              component={VoiceSelectScreen}
              options={{title: '选择配音声音'}}
            />
            <Stack.Screen
              name="Progress"
              component={ProgressScreen}
              options={{title: '处理中', headerBackVisible: false}}
            />
            <Stack.Screen
              name="Result"
              component={ResultScreen}
              options={{title: '配音完成 🎉', headerBackVisible: false}}
            />
          </Stack.Navigator>
        </NavigationContainer>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
