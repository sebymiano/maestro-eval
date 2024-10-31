# How to collect hotspot info with Intel Vtune Profiler

1. Run the following command to collect hotspot information:
```bash
sudo /opt/intel/oneapi/vtune/2025.0/bin64/vtune -collect hotspots -result-dir r002hs -quiet sudo ./cl-scr --lcores 1,3 -w 0000:51:00.1 -w 0000:51:00.0
```

2. After the command completes, you can view the results in the specified result directory (`r002hs` in this case).

```bash
sudo /opt/intel/oneapi/vtune/2025.0/bin64/vtune -report hotspots -result-dir r002hs
```