sealed class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class BackupInvalidFileException extends BackupException {
  const BackupInvalidFileException([
    super.message = 'This is not a valid ASCEND backup file.',
  ]);
}

final class BackupCorruptedException extends BackupException {
  const BackupCorruptedException([
    super.message = 'The backup file is damaged and cannot be restored.',
  ]);
}

final class BackupNewerVersionException extends BackupException {
  const BackupNewerVersionException([
    super.message =
    'This backup was created by a newer version of ASCEND. Update the app to restore it.',
  ]);
}

final class BackupPasswordRequiredException extends BackupException {
  const BackupPasswordRequiredException([
    super.message = 'This backup is encrypted. Enter its password.',
  ]);
}

final class BackupWrongPasswordException extends BackupException {
  const BackupWrongPasswordException([super.message = 'Wrong password.']);
}

final class BackupRestoreFailedException extends BackupException {
  const BackupRestoreFailedException([
    super.message = 'Restore failed. Your data was not changed.',
  ]);
}