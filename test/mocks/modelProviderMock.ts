interface StoreCall {
  model: unknown;
  store: unknown;
}

interface RequestCall {
  identifier: string;
  request: unknown;
}

export default class ModelProviderMock {
  calls: number;
  storeCalls: StoreCall[];
  nextStore: unknown;
  requestCalls: RequestCall[];
  nextRequest: unknown;

  constructor () {
    this.store = this.store.bind(this)
    this.request = this.request.bind(this)
    this.calls = 0
    this.storeCalls = []
    this.nextStore = false
    this.requestCalls = []
    this.nextRequest = false
  }

  store (model: unknown): Promise<void> {
    this.calls++
    this.storeCalls.push({model, store: this.nextStore})
    if (this.nextStore) {
      return Promise.resolve()
    }
    else {
      return Promise.reject()
    }
  }

  request (identifier: string): Promise<unknown> {
    this.calls++
    this.requestCalls.push({identifier, request: this.nextRequest})
    if (this.nextRequest) {
      return Promise.resolve(this.nextRequest)
    }
    else {
      return Promise.reject()
    }
  }
}
