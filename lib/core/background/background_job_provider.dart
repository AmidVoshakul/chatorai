import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'background_job_service.dart';

/// Provider for the [BackgroundJobService] singleton.
final backgroundJobServiceProvider = Provider<BackgroundJobService>((_) {
  return BackgroundJobService();
});
