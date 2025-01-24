declare module 'native-dns' {
    function Question(opts: any): { 'name': any, 'type': number, 'class': any };
    const Request: events.EventEmitter;
}
