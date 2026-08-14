import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class ChatMediaViewer extends StatelessWidget {
  const ChatMediaViewer({
    super.key,
    required this.url,
    required this.type,
    this.title,
  });

  final String url;
  final String type;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title ?? (type == 'video' ? 'Video' : 'Photo')),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
      body: type == 'video' ? _VideoBody(url: url) : InteractiveViewer(child: Center(child: Image.network(url))),
    );
  }
}

class _VideoBody extends StatefulWidget {
  const _VideoBody({required this.url});

  final String url;

  @override
  State<_VideoBody> createState() => _VideoBodyState();
}

class _VideoBodyState extends State<_VideoBody> {
  late final VideoPlayerController _controller;
  var _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _controller.play();
    }).catchError((error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.white)));
    }
    if (!_ready) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio == 0 ? 16 / 9 : _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            IconButton(
              iconSize: 64,
              color: Colors.white,
              icon: Icon(_controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
