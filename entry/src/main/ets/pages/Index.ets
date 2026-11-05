import { TtsPage } from './TtsPage';
import { AsrPage } from './AsrPage';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;

  @Builder
  tabBuilder(index: number, title: string, emoji: string) {
    Column() {
      Text(emoji)
        .fontSize(20)
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? '#007DFF' : '#999999')
        .margin({ top: 2 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        TtsPage()
      }
      .tabBar(this.tabBuilder(0, '语音转文字', '🔊'))

      TabContent() {
        AsrPage()
      }
      .tabBar(this.tabBuilder(1, '语音识别', '🎤'))
    }
    .barHeight(60)
    .layoutWeight(1)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }
}
