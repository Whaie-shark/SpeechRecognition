import localUnitTest from './LocalUnit.test';
import historyStoreTest from './HistoryStore.test';

export default function testsuite() {
  localUnitTest();
  historyStoreTest();
}
