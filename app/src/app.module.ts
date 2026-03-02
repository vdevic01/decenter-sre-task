import { MiddlewareConsumer, Module, NestModule } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { RequestCounterMiddleware } from "./common/middleware/request-counter.middleware";
import { HealthModule } from "./modules/health/health.module";
import { MetricsModule } from "./modules/metrics/metrics.module";

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true }), HealthModule, MetricsModule],
  controllers: [],
  providers: [],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(RequestCounterMiddleware).exclude("metrics").forRoutes("*");
  }
}
