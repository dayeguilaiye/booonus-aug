import React, { useState } from 'react';
import {
  Modal,
  View,
  StyleSheet,
} from 'react-native';
import {
  Text,
  TextInput,
  Button,
  Card,
} from 'react-native-paper';
import { colors } from '../styles/theme';

export default function InputDialog({
  visible,
  title,
  message,
  placeholder = '',
  defaultValue = '',
  onConfirm,
  onCancel,
  confirmText = '确定',
  cancelText = '取消',
}) {
  const [inputValue, setInputValue] = useState(defaultValue);

  const handleConfirm = () => {
    onConfirm(inputValue);
    setInputValue('');
  };

  const handleCancel = () => {
    onCancel();
    setInputValue('');
  };

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={handleCancel}
    >
      <View style={styles.overlay}>
        <Card style={styles.dialog}>
          <Card.Content>
            <Text style={styles.title}>{title}</Text>
            {message && <Text style={styles.message}>{message}</Text>}
            
            <TextInput
              mode="outlined"
              placeholder={placeholder}
              value={inputValue}
              onChangeText={setInputValue}
              style={styles.input}
              autoFocus
              onSubmitEditing={handleConfirm}
            />
            
            <View style={styles.buttonContainer}>
              <Button
                mode="text"
                onPress={handleCancel}
                style={styles.button}
                textColor={colors.onSurfaceVariant}
              >
                {cancelText}
              </Button>
              <Button
                mode="contained"
                onPress={handleConfirm}
                style={styles.button}
              >
                {confirmText}
              </Button>
            </View>
          </Card.Content>
        </Card>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  dialog: {
    width: '100%',
    maxWidth: 400,
    backgroundColor: colors.surface,
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
    color: colors.onSurface,
    marginBottom: 8,
  },
  message: {
    fontSize: 16,
    color: colors.onSurfaceVariant,
    marginBottom: 16,
  },
  input: {
    marginBottom: 20,
  },
  buttonContainer: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 8,
  },
  button: {
    minWidth: 80,
  },
});
