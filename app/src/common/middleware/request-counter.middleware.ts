import { Injectable, NestMiddleware } from "@nestjs/common";
import { NextFunction, Request, Response } from "express";
import { MetricsService } from "../../modules/metrics/metrics.service";

@Injectable()
export class RequestCounterMiddleware implements NestMiddleware {
  constructor(private readonly metricsService: MetricsService) {}

  use(_req: Request, _res: Response, next: NextFunction): void {
    this.metricsService.incrementRequests();
    next();
  }
}
