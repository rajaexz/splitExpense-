import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../application/message/message_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BroadcastVideoButton extends StatefulWidget {
  final String groupId;
  final List<CameraDescription>? cameras;

  const BroadcastVideoButton({
    Key? key,
    required this.groupId,
    this.cameras,
  }) : super(key: key);

  @override
  State<BroadcastVideoButton> createState() => _BroadcastVideoButtonState();
}

class _BroadcastVideoButtonState extends State<BroadcastVideoButton> {
  CameraController? _cameraController;
  String? _videoPath;

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (widget.cameras == null || widget.cameras!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not available')),
      );
      return;
    }

    try {
      _cameraController = CameraController(
        widget.cameras!.first,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      // Show recording dialog
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => _RecordingDialog(
          cameraController: _cameraController!,
          onStop: (path) {
            setState(() {
              _videoPath = path;
            });
          },
        ),
      );

      if (result == true && _videoPath != null && mounted) {
        _showBroadcastOptions();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showBroadcastOptions() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.padding16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Broadcast Video',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.margin16),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Send to Group'),
              subtitle: const Text('All members will see in group chat'),
              onTap: () {
                Navigator.pop(context);
                _broadcastVideo(sendIndividually: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Send Individually'),
              subtitle: const Text('Each member receives separate message'),
              onTap: () {
                Navigator.pop(context);
                _broadcastVideo(sendIndividually: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _broadcastVideo({required bool sendIndividually}) async {
    if (_videoPath == null) return;

    try {
      context.read<MessageCubit>().broadcastVideo(
            widget.groupId,
            File(_videoPath!),
            sendIndividually: sendIndividually,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sendIndividually
                ? 'Video sent to all members individually'
                : 'Video broadcasted to group',
          ),
        ),
      );

      setState(() {
        _videoPath = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.videocam),
      tooltip: 'Record & Send to All',
      onPressed: _startRecording,
    );
  }
}

class _RecordingDialog extends StatefulWidget {
  final CameraController cameraController;
  final Function(String) onStop;

  const _RecordingDialog({
    required this.cameraController,
    required this.onStop,
  });

  @override
  State<_RecordingDialog> createState() => _RecordingDialogState();
}

class _RecordingDialogState extends State<_RecordingDialog> {
  bool _isRecording = false;
  String? _videoPath;

  Future<void> _startRecording() async {
    try {
      await widget.cameraController.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _stopRecording() async {
    try {
      final video = await widget.cameraController.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _videoPath = video.path;
      });
      widget.onStop(_videoPath!);
      Navigator.of(context).pop(true);
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.padding16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 300,
              height: 400,
              child: CameraPreview(widget.cameraController),
            ),
            const SizedBox(height: AppDimensions.margin16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRecording)
                  ElevatedButton(
                    onPressed: _startRecording,
                    child: const Text('Start Recording'),
                  )
                else ...[
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.margin8),
                  ElevatedButton(
                    onPressed: _stopRecording,
                    child: const Text('Stop & Send'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
