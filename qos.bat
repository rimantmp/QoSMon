@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion

title Pengujian QoS Jaringan WLAN - SMK Negeri 3 Toraja Utara

:: =========================
:: Konfigurasi
:: =========================
set PING_TARGET=8.8.8.8
set PING_COUNT=20

:: =========================
:: Membuat folder output & nama file
:: =========================
if not exist "results" mkdir results
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set datetime=%%i

set md_output=results\qos_report_%datetime%.md
set csv_output=results\qos_data_%datetime%.csv

echo ==================================================
echo   PENGUJIAN QoS JARINGAN WLAN
echo   Lokasi
echo ==================================================
echo   Target Ping  : %PING_TARGET%
echo   Ping Count   : %PING_COUNT%
echo   Waktu        : %date% %time%
echo ==================================================
echo.
echo   Progress: [..........] 0/3 (0%%)
echo.

:: =========================
:: Header Markdown
:: =========================
echo # Laporan Pengujian QoS Jaringan WLAN> %md_output%
echo.>> %md_output%
echo **Penelitian:** ANALISIS QOS JARINGAN WLAN PADA SMK NEGERI 3 TORAJA UTARA>> %md_output%
echo.>> %md_output%
echo --->> %md_output%
echo.>> %md_output%
echo ## Informasi Pengujian>> %md_output%
echo.>> %md_output%
echo ^| Item ^| Detail ^|>> %md_output%
echo ^|:-----^|:-------^|>> %md_output%
echo ^| Tanggal ^| %date% ^|>> %md_output%
echo ^| Waktu ^| %time% ^|>> %md_output%
echo ^| Target Ping ^| %PING_TARGET% ^|>> %md_output%
echo ^| Jumlah Ping ^| %PING_COUNT% paket ^|>> %md_output%
echo.>> %md_output%
echo --->> %md_output%
echo.>> %md_output%

:: =========================
:: Header CSV
:: =========================
echo Timestamp,Avg_Delay_ms,Min_Delay_ms,Max_Delay_ms,Packet_Loss_pct,Download_Mbps,Upload_Mbps,Ping_Speedtest_ms> %csv_output%

:: =========================
:: 1. PING TEST
:: =========================
echo   [1/3] Menjalankan Ping Test ke %PING_TARGET%...

echo ## 1. Ping Test>> %md_output%
echo.>> %md_output%
echo Target: %PING_TARGET% ^| Jumlah Paket: %PING_COUNT%>> %md_output%
echo.>> %md_output%
echo ^`^`^`>> %md_output%

:: Jalankan ping dan simpan ke file temp
ping %PING_TARGET% -n %PING_COUNT% > temp_ping.txt 2>&1
type temp_ping.txt >> %md_output%

echo ^`^`^`>> %md_output%
echo.>> %md_output%

:: Parse hasil ping untuk mendapatkan statistik
set "avg_delay=0"
set "min_delay=0"
set "max_delay=0"
set "pkt_loss=0"

for /f "tokens=*" %%a in ('findstr /C:"Average" temp_ping.txt') do (
    for /f "tokens=9 delims=, " %%b in ("%%a") do (
        set "avg_val=%%b"
        set "avg_delay=!avg_val:ms=!"
    )
)
for /f "tokens=*" %%a in ('findstr /C:"Minimum" temp_ping.txt') do (
    for /f "tokens=3 delims=, " %%b in ("%%a") do (
        set "min_val=%%b"
        set "min_delay=!min_val:ms=!"
    )
)
for /f "tokens=*" %%a in ('findstr /C:"Minimum" temp_ping.txt') do (
    for /f "tokens=6 delims=, " %%b in ("%%a") do (
        set "max_val=%%b"
        set "max_delay=!max_val:ms=!"
    )
)

:: Parse packet loss menggunakan PowerShell (lebih akurat)
for /f %%a in ('powershell -NoProfile -Command "(Select-String -Path temp_ping.txt -Pattern '\((\d+)%%' | ForEach-Object { $_.Matches.Groups[1].Value })"') do set "pkt_loss=%%a"

:: Tampilkan ringkasan ping di terminal
echo.
echo     Avg Delay  : !avg_delay! ms
echo     Min Delay  : !min_delay! ms
echo     Max Delay  : !max_delay! ms
echo     Packet Loss: !pkt_loss!%%
echo.

:: Tulis ringkasan ke markdown
echo ### Ringkasan Ping>> %md_output%
echo.>> %md_output%
echo ^| Parameter ^| Nilai ^|>> %md_output%
echo ^|:----------^|:------^|>> %md_output%
echo ^| Avg Delay ^| !avg_delay! ms ^|>> %md_output%
echo ^| Min Delay ^| !min_delay! ms ^|>> %md_output%
echo ^| Max Delay ^| !max_delay! ms ^|>> %md_output%
echo ^| Packet Loss ^| !pkt_loss!%% ^|>> %md_output%
echo.>> %md_output%
echo --->> %md_output%
echo.>> %md_output%

echo   Progress: [####......] 1/3 (33%%)
echo.

:: =========================
:: 2. SPEEDTEST
:: =========================
echo   [2/3] Menjalankan Speedtest...

set "dl_speed=N/A"
set "ul_speed=N/A"
set "sp_ping=N/A"

echo ## 2. Speedtest>> %md_output%
echo.>> %md_output%

where speedtest.exe >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    echo ^`^`^`>> %md_output%
    speedtest.exe --accept-license --accept-gdpr > temp_speedtest.txt 2>&1
    type temp_speedtest.txt >> %md_output%
    echo ^`^`^`>> %md_output%
    echo.>> %md_output%

    :: Parse speedtest results dengan PowerShell
    for /f %%a in ('powershell -NoProfile -Command "if (Test-Path temp_speedtest.txt) { $c = Get-Content temp_speedtest.txt -Raw; if ($c -match 'Download:\s+([\d.]+)\s+Mbps') { $Matches[1] } else { 'N/A' } } else { 'N/A' }"') do set "dl_speed=%%a"
    for /f %%a in ('powershell -NoProfile -Command "if (Test-Path temp_speedtest.txt) { $c = Get-Content temp_speedtest.txt -Raw; if ($c -match 'Upload:\s+([\d.]+)\s+Mbps') { $Matches[1] } else { 'N/A' } } else { 'N/A' }"') do set "ul_speed=%%a"
    for /f %%a in ('powershell -NoProfile -Command "if (Test-Path temp_speedtest.txt) { $c = Get-Content temp_speedtest.txt -Raw; if ($c -match 'Latency:\s+([\d.]+)\s+ms') { $Matches[1] } else { 'N/A' } } else { 'N/A' }"') do set "sp_ping=%%a"

    echo.
    echo     Download   : !dl_speed! Mbps
    echo     Upload     : !ul_speed! Mbps
    echo     Latency    : !sp_ping! ms
    echo.

    echo ### Ringkasan Speedtest>> %md_output%
    echo.>> %md_output%
    echo ^| Parameter ^| Nilai ^|>> %md_output%
    echo ^|:----------^|:------^|>> %md_output%
    echo ^| Download ^| !dl_speed! Mbps ^|>> %md_output%
    echo ^| Upload ^| !ul_speed! Mbps ^|>> %md_output%
    echo ^| Latency ^| !sp_ping! ms ^|>> %md_output%
    echo.>> %md_output%
) else (
    echo     [SKIP] speedtest.exe tidak ditemukan.
    echo     Install: winget install Ookla.Speedtest.CLI
    echo.
    echo ^> **speedtest.exe tidak ditemukan.** Install dengan: `winget install Ookla.Speedtest.CLI`>> %md_output%
    echo.>> %md_output%
)
echo --->> %md_output%
echo.>> %md_output%

echo   Progress: [#######...] 2/3 (67%%)
echo.

:: =========================
:: 3. TRACEROUTE
:: =========================
echo   [3/3] Menjalankan Traceroute...

echo ## 3. Traceroute>> %md_output%
echo.>> %md_output%
echo Target: google.com>> %md_output%
echo.>> %md_output%
echo ^`^`^`>> %md_output%

tracert -d -w 3000 google.com > temp_tracert.txt 2>&1
type temp_tracert.txt >> %md_output%

echo ^`^`^`>> %md_output%
echo.>> %md_output%
echo --->> %md_output%
echo.>> %md_output%

echo.
echo   Progress: [##########] 3/3 (100%%)
echo.

:: =========================
:: Simpan CSV
:: =========================
echo %datetime%,!avg_delay!,!min_delay!,!max_delay!,!pkt_loss!,!dl_speed!,!ul_speed!,!sp_ping!>> %csv_output%

echo   Data CSV disimpan: %csv_output%
echo.

:: =========================
:: Penilaian QoS (TIPHON)
:: =========================
echo ## 4. Penilaian QoS (Standar TIPHON)>> %md_output%
echo.>> %md_output%
echo ### Standar Referensi>> %md_output%
echo.>> %md_output%
echo ^| Kategori ^| Delay ^| Packet Loss ^|>> %md_output%
echo ^|:------^|:------^|:------^|>> %md_output%
echo ^| Sangat Bagus (4) ^| ^<150ms ^| 0%% ^|>> %md_output%
echo ^| Bagus (3) ^| 150-300ms ^| 0-3%% ^|>> %md_output%
echo ^| Sedang (2) ^| 300-450ms ^| 3-15%% ^|>> %md_output%
echo ^| Buruk (1) ^| ^>450ms ^| ^>25%% ^|>> %md_output%
echo.>> %md_output%

:: Penilaian delay
set "delay_kategori=Buruk"
set "delay_indeks=1"

for /f %%a in ('powershell -NoProfile -Command "if ([double]'!avg_delay!' -lt 150) {'SangatBagus'} elseif ([double]'!avg_delay!' -lt 300) {'Bagus'} elseif ([double]'!avg_delay!' -lt 450) {'Sedang'} else {'Buruk'}"') do set "delay_kat=%%a"

if "!delay_kat!"=="SangatBagus" (set "delay_kategori=Sangat Bagus" & set "delay_indeks=4")
if "!delay_kat!"=="Bagus" (set "delay_kategori=Bagus" & set "delay_indeks=3")
if "!delay_kat!"=="Sedang" (set "delay_kategori=Sedang" & set "delay_indeks=2")
if "!delay_kat!"=="Buruk" (set "delay_kategori=Buruk" & set "delay_indeks=1")

:: Penilaian packet loss
set "loss_kategori=Buruk"
set "loss_indeks=1"

for /f %%a in ('powershell -NoProfile -Command "if ([double]'!pkt_loss!' -le 0) {'SangatBagus'} elseif ([double]'!pkt_loss!' -le 3) {'Bagus'} elseif ([double]'!pkt_loss!' -le 15) {'Sedang'} else {'Buruk'}"') do set "loss_kat=%%a"

if "!loss_kat!"=="SangatBagus" (set "loss_kategori=Sangat Bagus" & set "loss_indeks=4")
if "!loss_kat!"=="Bagus" (set "loss_kategori=Bagus" & set "loss_indeks=3")
if "!loss_kat!"=="Sedang" (set "loss_kategori=Sedang" & set "loss_indeks=2")
if "!loss_kat!"=="Buruk" (set "loss_kategori=Buruk" & set "loss_indeks=1")

echo ### Hasil Penilaian>> %md_output%
echo.>> %md_output%
echo ^| Parameter ^| Nilai ^| Kategori ^| Indeks ^|>> %md_output%
echo ^|:-------^|:------^|:------^|:------^|>> %md_output%
echo ^| Delay ^| !avg_delay! ms ^| !delay_kategori! ^| !delay_indeks! ^|>> %md_output%
echo ^| Packet Loss ^| !pkt_loss!%% ^| !loss_kategori! ^| !loss_indeks! ^|>> %md_output%
echo.>> %md_output%
echo --->> %md_output%
echo.>> %md_output%

echo *Laporan digenerate otomatis pada %date% %time%*>> %md_output%

:: =========================
:: Bersihkan file temp
:: =========================
if exist temp_ping.txt del temp_ping.txt
if exist temp_speedtest.txt del temp_speedtest.txt
if exist temp_tracert.txt del temp_tracert.txt

:: =========================
:: Selesai
:: =========================
echo ==================================================
echo   PENGUJIAN SELESAI!
echo ==================================================
echo   Laporan Markdown : %md_output%
echo   Data CSV         : %csv_output%
echo ==================================================
echo.

pause
