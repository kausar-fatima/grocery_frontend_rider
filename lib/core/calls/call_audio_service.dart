import 'dart:developer' as developer;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

/// Wraps the Agora RTC engine: joining/leaving the audio channel for a call.
/// Knows nothing about call signaling (accept/decline) — that stays in
/// CallsCubit; this only handles the actual audio transport.
class CallAudioService {
  RtcEngine? _engine;
  bool get isActive => _engine != null;

  Future<void> joinChannel({
    required String appId,
    required String channelName,
    required String token,
    required int uid,
  }) async {
    if (_engine != null) {
      // Already in a channel — leave first (defensive, shouldn't normally happen).
      await leaveChannel();
    }

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      developer.log('Microphone permission denied', name: 'CallAudioService');
      return;
    }

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(appId: appId));
    await _engine!.enableAudio();
    await _engine!.setDefaultAudioRouteToSpeakerphone(true);
    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
    developer.log(
      'Joined Agora channel: $channelName',
      name: 'CallAudioService',
    );
  }

  Future<void> toggleMute(bool muted) async {
    await _engine?.muteLocalAudioStream(muted);
  }

  Future<void> toggleSpeaker(bool speakerOn) async {
    await _engine?.setEnableSpeakerphone(speakerOn);
  }

  Future<void> leaveChannel() async {
    if (_engine == null) return;
    await _engine!.leaveChannel();
    await _engine!.release();
    _engine = null;
    developer.log('Left Agora channel', name: 'CallAudioService');
  }
}
