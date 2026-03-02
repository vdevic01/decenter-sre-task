import { Injectable } from "@nestjs/common";
import { Counter, Registry } from "prom-client";

@Injectable()
export class MetricsService {
  private readonly registry: Registry;
  private readonly httpRequestsTotal: Counter;

  constructor() {
    this.registry = new Registry();

    this.httpRequestsTotal = new Counter({
      name: "http_requests_total",
      help: "Total number of HTTP requests received",
      registers: [this.registry],
    });
  }

  incrementRequests(): void {
    this.httpRequestsTotal.inc();
  }

  async getMetrics(): Promise<string> {
    return this.registry.metrics();
  }

  getContentType(): string {
    return this.registry.contentType;
  }
}
