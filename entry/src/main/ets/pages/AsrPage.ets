import { speechRecognizer } from '@kit.CoreSpeechKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';

@Component
export struct AsrPage {
  @State isRecording: boolean = false;
  @State recognizedText: string = '';
  @State isRecognizing: boolean = false;
  private asrEngine: speechRecognizer.SpeechRecognitionEngine | null = null;
  private currentSessionId: string = '';

  async aboutToAppear() {
    // 初始化语音识别引擎（离线模式 online=1）
    try {
      const config: speechRecognizer.CreateEngineParams = {
        language: 'zh-CN',
        online: 1
      };
      this.asrEngine = await speechRecognizer.createEngine(config);

      this.asrEngine.setListener({
        onStart: (sessionId: string, eventMessage: string) => {
          this.isRecording = true;
          this.isRecognizing = true;
        },
        onEvent: (sessionId: string, eventCode: number, eventMessage: string) => {
          // 事件回调，暂不处理
        },
        onResult: (sessionId: string, result: speechRecognizer.SpeechRecognitionResult) => {
          this.recognizedText = result.result;
          this.isRecognizing = false;
          this.isRecording = false;
        },
        onComplete: (sessionId: string, eventMessage: string) => {
          this.isRecognizing = false;
          this.isRecording = false;
        },
        onError: (sessionId: string, errorCode: number, errorMessage: string) => {
          console.error('ASR error: ' + errorMessage);
          this.isRecognizing = false;
          this.isRecording = false;
          promptAction.showToast({ message: '识别失败，请重试' });
        }
      });
    } catch (err) {
      console.error('ASR init failed: ' + JSON.stringify(err));
    }
  }

  async aboutToDisappear() {
    try {
      if (this.asrEngine) {
        if (this.currentSessionId) {
          this.asrEngine.cancel(this.currentSessionId);
        }
        this.asrEngine.shutdown();
        this.asrEngine = null;
      }
    } catch (err) {
      console.error('ASR shutdown failed: ' + JSON.stringify(err));
    }
  }

  toggleRecording() {
    if (!this.asrEngine) {
      promptAction.showToast({ message: '语音识别未就绪' });
      return;
    }

    if (!this.isRecording) {
      // 开始录音
      try {
        this.recognizedText = '';
        this.currentSessionId = 'asr_' + Date.now().toString();
        const startParams: speechRecognizer.StartParams = {
          sessionId: this.currentSessionId,
          audioInfo: {
            audioType: 'pcm',
            sampleRate: 16000,
            soundChannel: 1,
            sampleBit: 16
          }
        };
        this.asrEngine.startListening(startParams);
      } catch (err) {
        console.error('Start listening failed: ' + JSON.stringify(err));
        this.isRecording = false;
        this.isRecognizing = false;
        promptAction.showToast({ message: '启动录音失败' });
      }
    } else {
      // 停止录音，结束识别
      try {
        this.asrEngine.finish(this.currentSessionId);
      } catch (err) {
        console.error('Finish recognition failed: ' + JSON.stringify(err));
        this.isRecording = false;
        this.isRecognizing = false;
      }
    }
  }

  copyResult() {
    if (!this.recognizedText || this.recognizedText.length === 0) {
      promptAction.showToast({ message: '暂无可复制的内容' });
      return;
    }
    try {
      const pasteData = pasteboard.createData(
        pasteboard.MIMETYPE_TEXT_PLAIN,
        this.recognizedText
      );
      const systemPasteboard = pasteboard.getSystemPasteboard();
      systemPasteboard.setData(pasteData).then(() => {
        promptAction.showToast({ message: '已复制到剪贴板' });
      }).catch((err: Error) => {
        console.error('Copy failed: ' + JSON.stringify(err));
        promptAction.showToast({ message: '复制失败' });
      });
    } catch (err) {
      console.error('Copy exception: ' + JSON.stringify(err));
      promptAction.showToast({ message: '复制失败' });
    }
  }

  build() {
    Column() {
      // 中央录音按钮区域
      Column() {
        Stack({ alignContent: Alignment.Center }) {
          // 外圈光晕（录音时显示）
          if (this.isRecording) {
            Circle({ width: 180, height: 180 })
              .fill('#FFE0E0')
              .opacity(0.5)
          }

          // 主按钮
          Button() {
            Column() {
              Text(this.isRecording ? '⏹' : '🎤')
                .fontSize(40)
              Text(this.isRecording ? '停止录音' : '点击录音')
                .fontSize(14)
                .fontColor('#FFFFFF')
                .margin({ top: 8 })
            }
          }
          .width(140)
          .height(140)
          .borderRadius(70)
          .backgroundColor(this.isRecording ? '#E53935' : '#007DFF')
          .onClick(() => {
            this.toggleRecording();
          })
        }
        .width('100%')
        .height(220)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)

      // 识别结果区域
      Column() {
        Text('识别结果')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('90%')
          .margin({ bottom: 12 })

        Column() {
          if (this.recognizedText.length === 0) {
            Text(this.isRecognizing ? '正在识别...' : '暂无识别结果')
              .fontSize(14)
              .fontColor('#999999')
          } else {
            Text(this.recognizedText)
              .fontSize(16)
              .fontColor('#333333')
              .width('100%')
          }
        }
        .width('90%')
        .height(120)
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)

        Button('📋 复制结果')
          .width('90%')
          .height(45)
          .margin({ top: 16 })
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .onClick(() => {
            this.copyResult();
          })
      }
      .width('100%')
      .padding({ bottom: 30 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
