class AppConstants {
  static const String appName = 'Gofer.ai';
  static const String githubApiBase = 'https://api.github.com';
  static const String goferRepo = String.fromEnvironment(
    'GOFER_REPO',
    defaultValue: 'LiuGus404/gofer-marketplace',
  );
  static const String githubClientId = String.fromEnvironment(
    'GITHUB_CLIENT_ID',
    defaultValue: 'Ov23liF1bogcYVGUkcTR',
  );
}
