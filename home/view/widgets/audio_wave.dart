import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:client/core/theme/app_pallete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AudioWave extends StatefulWidget {
  final String path; // 获得所选择的音频文件的 path
  const AudioWave({
    super.key,
    required this.path,
  });

  @override
  State<AudioWave> createState() => _AudioWaveState();
}

class _AudioWaveState extends State<AudioWave> {
  final PlayerController playerController = PlayerController(); // playerController 用来控制音频文件的播放和记录播放状态 (和 upload_song_page 里的 textcontroller 区分开来)

  @override
  void initState() {
    super.initState();
    initAudioPlayer();
  }

  void initAudioPlayer() async {
    await playerController.preparePlayer(path: widget.path); // 根据初始化时传入的 path (音频文件地址) 对 player 播放器进行初始化
  }

  Future<void> playAndPause() async {
    if (!playerController.playerState.isPlaying) {
      await playerController.startPlayer(finishMode: FinishMode.stop); // 开启视频
    } else if (!playerController.playerState.isPaused) {
      await playerController.pausePlayer(); // 暂停视频
    }
    setState(() {}); // 更新 UI
  }

  @override
  void dispose() {
    playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: playAndPause, // 将这个函数 playAndPause 设置为这个按钮的回调函数
          icon: Icon(
            playerController.playerState.isPlaying // 根据 player 的状态 设置按钮形状
                ? CupertinoIcons.pause_solid
                : CupertinoIcons.play_arrow_solid,
          ),
        ),
        Expanded(
          child: AudioFileWaveforms( // 播放器组件
            size: const Size(double.infinity, 100), // 必须要使用 Expanded 的原因在于此：因为设置了宽度为 double.infinity 即占据所有的位置 但是还有其他的 children (IconBotton)所以用 Expanded 包裹声明为占据剩余位置的全部
            playerController: playerController, // 在 initState 里已经使用了初始化的操作 指定了 AudioFileWaveforms 显示的文件
            playerWaveStyle: const PlayerWaveStyle(
              fixedWaveColor: Pallete.borderColor,
              liveWaveColor: Pallete.gradient2,
              spacing: 6,
              showSeekLine: false,
            ),
          ),
        ),
      ],
    );
  }
}
