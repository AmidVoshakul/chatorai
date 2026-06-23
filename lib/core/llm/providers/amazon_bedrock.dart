/// Amazon Bedrock provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// Amazon Bedrock — AWS-native foundation models.
/// Note: Requires AWS SigV4 signing (IAM credentials).
/// Basic AuthConfig is a placeholder — runtime handles signing.
ProviderConfig amazonBedrockProvider() => ProviderConfig.basic(
  id: 'amazon-bedrock',
  name: 'Amazon Bedrock',
  description:
      'Amazon Bedrock — AWS-native foundation models '
      '(Claude, Llama, Mistral, Titan).',
  baseUrl: 'https://bedrock-runtime.us-east-1.amazonaws.com',
  auth: AuthConfig.aws(
    awsAccessKeyId: '',
    awsSecretAccessKey: '',
    awsRegion: 'us-east-1',
  ),
  sdk: 'bedrock',
  enabled: false,
);
