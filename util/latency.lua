-- RFC-2544 throughput testing.
--
-- SPDX-License-Identifier: BSD-3-Clause

package.path = package.path ..";?.lua;test/?.lua;app/?.lua;../?.lua"

require "Pktgen";

local sendport			= "0";
local recvport			= "1";
local duration			= 10000;
local pauseTime			= 1000;
local max_rate 			= 100.0; -- Gbps
local background_rate	= 10;    -- Gbps
local probe_rate		= 1000;  -- packets per second
local probe_sz			= 86;    -- bytes (https://github.com/pktgen/Pktgen-DPDK/issues/83)
local output_filename   = "latency.csv";

local function testLatency()
	local probes = probe_rate * (duration / 1000);

	pktgen.set(sendport, "count", 0);
	pktgen.set(sendport, "rate", 100.0 * background_rate / max_rate);
	pktgen.set(sendport, "size", probe_sz);

	pktgen.latency(sendport, "enable");
	pktgen.latency(recvport, "enable");

	pktgen.latsampler_params(recvport, "simple", probes, probe_rate, output_filename);

	pktgen.start(sendport);
	pktgen.latsampler(recvport, "enable");
	pktgen.delay(duration);
	pktgen.latsampler(recvport, "disable");
	pktgen.stop(sendport);
end

function main()
	pktgen.screen("off");

	print("\nMeasuring latency... ");
	testLatency()
	print("done\n");

	pktgen.quit();
end

main();
