import { describe, it, expect } from '@ohos/hypium';
import { HistoryStore, HistoryItem } from '../main/ets/utils/HistoryStore';

export default function historyStoreTest() {
  describe('HistoryStoreTest', () => {

    it('addItem_插入到列表最前面', 0, () => {
      const existing: HistoryItem[] = [
        { text: '第二条', time: '2026-11-05 10:00' }
      ];
      const newItem: HistoryItem = { text: '第一条', time: '2026-11-05 10:01' };
      const result = HistoryStore.addItem(existing, newItem);

      expect(result.length).assertEqual(2);
      expect(result[0].text).assertEqual('第一条');
      expect(result[1].text).assertEqual('第二条');
    });

    it('addItem_空列表添加一条', 0, () => {
      const newItem: HistoryItem = { text: '测试', time: '2026-11-05 10:00' };
      const result = HistoryStore.addItem([], newItem);

      expect(result.length).assertEqual(1);
      expect(result[0].text).assertEqual('测试');
    });

    it('addItem_超过50条自动截断最老的', 0, () => {
      // 构造 50 条历史
      let list: HistoryItem[] = [];
      for (let i = 0; i < 50; i++) {
        list.push({ text: '老记录' + i, time: '2026-11-05 10:' + i.toString().padStart(2, '0') });
      }
      const newItem: HistoryItem = { text: '最新记录', time: '2026-11-05 11:00' };
      const result = HistoryStore.addItem(list, newItem);

      expect(result.length).assertEqual(50);
      expect(result[0].text).assertEqual('最新记录');
      // 原数组50条，加1条后51条，截断后最后一条是原数组的倒数第2条（老记录48）
      expect(result[49].text).assertEqual('老记录48');
    });

    it('serialize_正常序列化', 0, () => {
      const list: HistoryItem[] = [
        { text: '你好', time: '2026-11-05 10:00' }
      ];
      const json = HistoryStore.serialize(list);
      expect(json).assertContain('你好');
    });

    it('deserialize_正常反序列化', 0, () => {
      const json = '[{"text":"你好","time":"2026-11-05 10:00"}]';
      const result = HistoryStore.deserialize(json);
      expect(result.length).assertEqual(1);
      expect(result[0].text).assertEqual('你好');
    });

    it('deserialize_非法JSON返回空数组', 0, () => {
      const result = HistoryStore.deserialize('not a json');
      expect(result.length).assertEqual(0);
    });

    it('deserialize_空字符串返回空数组', 0, () => {
      const result = HistoryStore.deserialize('');
      expect(result.length).assertEqual(0);
    });

    it('deserialize_非数组JSON返回空数组', 0, () => {
      const result = HistoryStore.deserialize('{"text":"hello"}');
      expect(result.length).assertEqual(0);
    });

    it('isEmpty_空列表返回true', 0, () => {
      expect(HistoryStore.isEmpty([])).assertTrue();
    });

    it('isEmpty_非空列表返回false', 0, () => {
      const list: HistoryItem[] = [{ text: 'a', time: 't' }];
      expect(HistoryStore.isEmpty(list)).assertFalse();
    });

    it('formatTime_格式正确', 0, () => {
      const date = new Date(2026, 10, 5, 14, 30); // 月份从0开始，10月=11月
      const formatted = HistoryStore.formatTime(date);
      expect(formatted).assertEqual('2026-11-05 14:30');
    });

    it('formatTime_个位数补零', 0, () => {
      const date = new Date(2026, 0, 1, 9, 5);
      const formatted = HistoryStore.formatTime(date);
      expect(formatted).assertEqual('2026-01-01 09:05');
    });

    it('truncateText_短文本不截断', 0, () => {
      const text = '你好世界';
      const result = HistoryStore.truncateText(text, 500);
      expect(result).assertEqual('你好世界');
    });

    it('truncateText_超过长度截断', 0, () => {
      let text = '';
      for (let i = 0; i < 600; i++) {
        text += 'a';
      }
      const result = HistoryStore.truncateText(text, 500);
      expect(result.length).assertEqual(500);
    });

    it('truncateText_默认500上限', 0, () => {
      let text = '';
      for (let i = 0; i < 600; i++) {
        text += '字';
      }
      const result = HistoryStore.truncateText(text);
      expect(result.length).assertEqual(500);
    });

  });
}
