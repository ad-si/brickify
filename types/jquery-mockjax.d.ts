interface MockJaxSettings {
  logging?: boolean;
  status?: number;
  statusText?: string;
  responseTime?: number;
  isTimeout?: boolean;
  contentType?: string;
  response?: (settings: any) => void;
  responseText?: string | Object;
  responseXML?: string;
  proxy?: string;
  proxyType?: string;
  lastModified?: string;
  etag?: string;
  headers?: Object;
  url?: string | RegExp;
  data?: Object;
  type?: string;
  urlParams?: string[];
}

interface JQueryStatic {
  mockjax: {
    (options: MockJaxSettings): number;
    clear(id?: number): void;
    mockedAjaxCalls(): any[];
    unmockedAjaxCalls(): any[];
  };
  mockjaxSettings: MockJaxSettings;
}
