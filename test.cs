using System;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Serilog;
using Serilog.Core;
using Spectacles.NET.Types;
using Spectacles.NET.Gateway;
using Spectacles.NET.Gateway.Event;
using Spectacles.NET.Broker.Amqp;
using Spectacles.NET.Util.Logging;

namespace Aurora.Core
{
    public class GatewayHandler
    {
        private readonly Logger _logger = new LoggerConfiguration()
            .WriteTo.Console()
            .CreateLogger();

        private const int DiscordShardingFormula = 22;

        private const LogLevel MinimumLogLevel = LogLevel.DEBUG;

        private readonly Uri _brokerUri;

        private readonly AmqpBroker _broker;
        private readonly Cluster _gatewayCluster;

        private int _shardCount
            => _gatewayCluster.Gateway.ShardCount;

        public GatewayHandler(string token, string brokerName, Uri brokerUri, IdentifyOptions identifyOptions, int? shardCount)
        {
            _brokerUri = brokerUri;
            _gatewayCluster = shardCount.HasValue
                ? new Cluster(token, shardCount, identifyOptions)
                : new Cluster(token, identifyOptions: identifyOptions);
            _broker = new AmqpBroker(brokerName);

            _gatewayCluster.Log += OnLog;
            _gatewayCluster.Error += OnError;
            _gatewayCluster.Dispatch += (_, args) => Task.Run(() =>
                _broker.PublishAsync(Enum.GetName(typeof(GatewayEvent), args.Event),
                    Encoding.UTF8.GetBytes(JsonSerializer.Serialize(args.Data,
                        new JsonSerializerOptions { IgnoreNullValues = true }))));

            _broker.Receive += BrokerOnReceive;
        }

        public async Task ConnectAsync()
        {
            await _gatewayCluster.ConnectAsync();
            await _broker.ConnectAsync(_brokerUri);

            await Task.WhenAll(_gatewayCluster.Shards.Values.Select(s => _broker.SubscribeAsync($"{s.Id}")));

            await _broker.SubscribeAsync("SEND");
        }

        // Thank you Yukine. Guys please go check out the bot named Senpai by Yukine#8080. An awesome bot by an awesome dev.
        private void BrokerOnReceive(object? _, AmqpReceiveEventArgs e)
        {
            Task.Run(async () =>
            {
                var @event = e.Event;

                if (int.TryParse(@event, out var shardId))
                {
                    if (!_gatewayCluster.Shards.TryGetValue(shardId, out var shard)) return;
                    var packet = JsonSerializer.Deserialize<SendPacket>(Encoding.UTF8.GetString(e.Data));
                    await shard.SendAsync(packet.OpCode, packet.Data);
                }
                else if (@event == "SEND")
                {
                    var data = JsonSerializer.Deserialize<SendableDispatch>(Encoding.UTF8.GetString(e.Data));
                    var dataBytes = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(data.Packet));

                    if (data.GuildId == "*")
                    {
                        var tasks = new Task[_shardCount];
                        for (var i = 0; i < _shardCount; i++)
                            tasks[i] = _broker.PublishAsync(i.ToString(), dataBytes);
                        await Task.WhenAll(tasks);
                    }
                    else
                    {
                        var calculatedShardId = (long.Parse(data.GuildId) >> DiscordShardingFormula) % _gatewayCluster.Shards.Count;
                        await _broker.PublishAsync(calculatedShardId.ToString(), dataBytes);
                    }
                }

                _broker.Ack(e.Event, e.DeliveryTag);
            }).Wait();
        }


        private void OnLog(object? _, LogEventArgs e)
        {
            if (e.LogLevel <= MinimumLogLevel) return;

            var generalMessage = $"[{e.Sender}] {e.Message}";

            switch (e.LogLevel)
            {
                case LogLevel.TRACE:
                    _logger.Debug($"[TRACE] {generalMessage}");
                    break;
                case LogLevel.DEBUG:
                    _logger.Debug(generalMessage);
                    break;
                case LogLevel.INFO:
                    _logger.Information(generalMessage);
                    break;
                case LogLevel.WARN:
                    _logger.Warning(generalMessage);
                    break;
            }
        }

        private void OnError(object? _, ExceptionEventArgs e)
            => _logger.Error($"[{e.ShardId}] {e.Exception}");
    }
}