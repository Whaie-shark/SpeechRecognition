export interface HistoryItem {
  text: string;
  time: string;
}

export class HistoryStore {
  static readonly MAX_ITEMS: number = 50;

  /**
   * 添加一条历史，插到最前面，超过 MAX_ITEMS 则砍掉最老的
   */
  static addItem(list: HistoryItem[], item: HistoryItem): HistoryItem[] {
    const newList: HistoryItem[] = [item, ...list];
    if (newList.length > HistoryStore.MAX_ITEMS) {
      return newList.slice(0, HistoryStore.MAX_ITEMS);
    }
    return newList;
  }

  /**
   * 序列化为 JSON 字符串
   */
  static serialize(list: HistoryItem[]): string {
    return JSON.stringify(list);
  }

  /**
   * 从 JSON 字符串反序列化，失败返回空数组
   */
  static deserialize(jsonStr: string): HistoryItem[] {
    try {
      const parsed: Object = JSON.parse(jsonStr) as Object;
      if (Array.isArray(parsed)) {
        return parsed as HistoryItem[];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /**
   * 判断列表是否为空
   */
  static isEmpty(list: HistoryItem[]): boolean {
    return list.length === 0;
  }

  /**
   * 格式化当前时间为 "YYYY-MM-DD HH:mm"
   */
  static formatTime(date: Date): string {
    const y = date.getFullYear();
    const m = (date.getMonth() + 1).toString().padStart(2, '0');
    const d = date.getDate().toString().padStart(2, '0');
    const h = date.getHours().toString().padStart(2, '0');
    const min = date.getMinutes().toString().padStart(2, '0');
    return `${y}-${m}-${d} ${h}:${min}`;
  }

  /**
   * 截断文本到指定长度（TTS 输入限制）
   */
  static truncateText(text: string, maxLen: number = 500): string {
    if (text.length > maxLen) {
      return text.substring(0, maxLen);
    }
    return text;
  }
}
