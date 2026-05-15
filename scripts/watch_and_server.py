#!/usr/bin/env python3

import sys
import os
import subprocess
import shutil
import socket
import time
import glob
import threading


def get_local_ip():
    try:
        output = subprocess.check_output(
            ["ipconfig", "getifaddr", "en0"], stderr=subprocess.DEVNULL
        )
        return output.decode("utf-8").strip()
    except subprocess.CalledProcessError:
        try:
            output = subprocess.check_output(
                ["hostname", "-I"], stderr=subprocess.DEVNULL
            )
            return output.decode("utf-8").split()[0].strip()
        except (subprocess.CalledProcessError, IndexError):
            pass

    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return None


def patch_ipa(ipa_file, deb_file, output_ipa):
    print(f"\n[+] Patching IPA with cyan using {os.path.basename(deb_file)}...")
    try:
        subprocess.run(
            [
                "cyan",
                "-i",
                ipa_file,
                "-o",
                output_ipa,
                "-f",
                deb_file,
                "-u",
                "--overwrite",
            ],
            check=True,
        )
        print("[+] Patch complete.")
        return True
    except subprocess.CalledProcessError:
        print("[-] Patch failed.")
        return False
    except FileNotFoundError:
        print(
            "[-] 'cyan' command not found. Please ensure it is installed and in your PATH."
        )
        return False


def get_newest_deb(directory):
    deb_files = glob.glob(os.path.join(directory, "*.deb"))
    if not deb_files:
        return None
    return max(deb_files, key=os.path.getmtime)


def start_server(out_dir):
    server_process = subprocess.Popen(
        [sys.executable, "-m", "http.server", "8000", "--directory", out_dir]
    )
    return server_process


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {os.path.basename(sys.argv[0])} <file.ipa> <file.deb>")
        sys.exit(1)

    ipa_file = None
    initial_deb_file = None

    for arg in sys.argv[1:]:
        if arg.endswith(".ipa"):
            ipa_file = arg
        elif arg.endswith(".deb"):
            initial_deb_file = arg
        else:
            print(f"Unknown file type: {arg}")
            sys.exit(1)

    if not ipa_file or not initial_deb_file:
        print("You must provide one .ipa and one .deb file.")
        sys.exit(1)

    out_dir = "/tmp/ipa_patched"
    os.makedirs(out_dir, exist_ok=True)

    ipa_name = os.path.basename(ipa_file)
    output_ipa = os.path.join(out_dir, ipa_name)

    deb_dir = os.path.dirname(os.path.abspath(initial_deb_file))
    current_deb_file = get_newest_deb(deb_dir) or initial_deb_file
    last_mtime = (
        os.path.getmtime(current_deb_file) if os.path.exists(current_deb_file) else 0
    )

    if not patch_ipa(ipa_file, current_deb_file, output_ipa):
        sys.exit(1)

    local_ip = get_local_ip() or "YOUR_IP"
    download_link = f"http://{local_ip}:8000/{ipa_name}"

    print()
    print("==========================================")
    print("Download link:")
    print(download_link)
    print("==========================================")
    print()

    try:
        if shutil.which("pbcopy"):
            subprocess.run(["pbcopy"], input=download_link.encode("utf-8"), check=True)
            print("[+] Download link copied to clipboard.")
    except Exception:
        pass

    print("[+] Starting HTTP server...")
    server_process = start_server(out_dir)

    print(f"[+] Watching for new .deb files in {deb_dir} every 2 seconds...")
    print("Press Ctrl+C to stop.")

    try:
        while True:
            time.sleep(2)
            newest_deb = get_newest_deb(deb_dir)
            if newest_deb:
                current_mtime = os.path.getmtime(newest_deb)
                if current_mtime > last_mtime:
                    print(
                        f"\n[*] Detected new/updated .deb file: {os.path.basename(newest_deb)}"
                    )
                    patch_ipa(ipa_file, newest_deb, output_ipa)
                    last_mtime = current_mtime
    except KeyboardInterrupt:
        print("\nStopping HTTP server and watcher...")
        server_process.terminate()
        server_process.wait()


if __name__ == "__main__":
    main()
