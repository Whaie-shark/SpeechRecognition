import { textToSpeech } from '@kit.CoreSpeechKit';
import { preferences } from '@kit.ArkData';
import { HistoryStore, HistoryItem } from '../utils/HistoryStore';

const PREF_NAME: string = 'tts_history';
const KEY_HISTORY: string = 'history';

@Component
export struct TtsPage {
  @State inputText: string = '';
  @State historyList: HistoryItem[] = [];
  @State isSpeaking: boolean = false;
  private ttsEngine: textToSpeech.TextToSpeechEngine | null = null;

  async aboutToAppear() {
    // 初始化 TTS 引擎（离线模式 online=1）
    try {
      const engineConfig: textToSpeech.CreateEngineParams = {
        language: 'zh-CN',
        person: 0,
        online: 1
      };
      this.ttsEngine = await textToSpeech.createEngine(engineConfig);
      // 设置监听器
      this.ttsEngine.setListener({
        onStart: (requestId: string, response: textToSpeech.StartResponse) => {
          this.isSpeaking = true;
        },
        onComplete: (requestId: string, response: textToSpeech.CompleteResponse) => {
          this.isSpeaking = false;
        },
        onStop: (requestId: string, response: textToSpeech.StopResponse) => {
          this.isSpeaking = false;
        },
        onError: (requestId: string, errorCode: number, errorMessage: string) => {
          console.error('TTS error: ' + errorMessage);
          this.isSpeaking = false;
        }
      });
    } catch (err) {
      console.error('TTS engine init failed: ' + JSON.stringify(err));
    }

    // 从本地存储加载历史
    await this.loadHistory();
  }

  async aboutToDisappear() {
    try {
      if (this.ttsEngine) {
        this.ttsEngine.shutdown();
        this.ttsEngine = null;
      }
    } catch (err) {
      console.error('TTS shutdown failed: ' + JSON.stringify(err));
    }
  }

  async loadHistory() {
    try {
      const pref = await preferences.getPreferences(getContext(this), PREF_NAME);
      const savedStr = await pref.get(KEY_HISTORY, '[]') as string;
      this.historyList = HistoryStore.deserialize(savedStr);
    } catch (err) {
      console.error('Load history failed: ' + JSON.stringify(err));
      this.historyList = [];
    }
  }

  async saveHistory() {
    try {
      const pref = await preferences.getPreferences(getContext(this), PREF_NAME);
      await pref.put(KEY_HISTORY, HistoryStore.serialize(this.historyList));
      await pref.flush();
    } catch (err) {
      console.error('Save history failed: ' + JSON.stringify(err));
    }
  }

  addToHistory(text: string) {
    const item: HistoryItem = {
      text: text,
      time: HistoryStore.formatTime(new Date())
    };
    this.historyList = HistoryStore.addItem(this.historyList, item);
    this.saveHistory();
  }

  speakText(text: string) {
    if (!text || text.trim().length === 0) {
      return;
    }
    if (!this.ttsEngine) {
      console.error('TTS engine not ready');
      return;
    }
    try {
      const requestId = 'tts_' + Date.now().toString();
      const speakParams: textToSpeech.SpeakParams = {
        requestId: requestId
      };
      this.ttsEngine.speak(text.trim(), speakParams);
      this.addToHistory(text.trim());
    } catch (err) {
      console.error('Speak failed: ' + JSON.stringify(err));
    }
  }

  build() {
    Column() {
      TextArea({ placeholder: '请输入要朗读的文字...', text: this.inputText })
        .width('90%')
        .height(160)
        .margin({ top: 20 })
        .fontSize(16)
        .borderRadius(8)
        .backgroundColor('#FFFFFF')
        .onChange((value: string) => {
          this.inputText = HistoryStore.truncateText(value, 500);
        })

      Button(this.isSpeaking ? '🔊 朗读中...' : '🔊 开始朗读')
        .width('90%')
        .height(50)
        .margin({ top: 20 })
        .fontSize(18)
        .fontColor('#FFFFFF')
        .backgroundColor(this.isSpeaking ? '#999999' : '#007DFF')
        .borderRadius(8)
        .enabled(!this.isSpeaking)
        .onClick(() => {
          this.speakText(this.inputText);
        })

      Row() {
        Text('历史记录')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('90%')
      .margin({ top: 24, bottom: 12 })

      if (HistoryStore.isEmpty(this.historyList)) {
        Column() {
          Text('暂无历史记录')
            .fontSize(14)
            .fontColor('#999999')
        }
        .width('90%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 8 }) {
          ForEach(this.historyList, (item: HistoryItem) => {
            ListItem() {
              Column() {
                Text(item.text)
                  .fontSize(14)
                  .fontColor('#333333')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                Text(item.time)
                  .fontSize(12)
                  .fontColor('#999999')
                  .margin({ top: 4 })
                  .width('100%')
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
            }
            .onClick(() => {
              this.inputText = item.text;
              this.speakText(item.text);
            })
          }, (item: HistoryItem) => item.time + item.text)
        }
        .width('90%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
