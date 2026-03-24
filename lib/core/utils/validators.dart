class Validators {
  const Validators._();

  static String? requiredField(String? value, {String label = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label es obligatorio';
    }

    return null;
  }

  static String? email(String? value) {
    final requiredError = requiredField(value, label: 'El correo');
    if (requiredError != null) {
      return requiredError;
    }

    final expression = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!expression.hasMatch(value!.trim())) {
      return 'Ingresa un correo valido';
    }

    return null;
  }

  static String? password(String? value) {
    final requiredError = requiredField(value, label: 'La contraseña');
    if (requiredError != null) {
      return requiredError;
    }

    if (value!.trim().length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    return null;
  }

  static String? shortText(String? value, {String label = 'El texto'}) {
    final requiredError = requiredField(value, label: label);
    if (requiredError != null) {
      return requiredError;
    }

    if (value!.trim().length < 3) {
      return '$label debe tener al menos 3 caracteres';
    }

    return null;
  }
}
