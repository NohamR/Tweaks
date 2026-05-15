#!/usr/bin/env python3

import sys
import os
import subprocess
import shutil
import socket


def get_local_ip():
    try:
        # Try macOS command
        output = subprocess.check_output(
            ["ipconfig", "getifaddr", "en0"], stderr=subprocess.DEVNULL
        )
        return output.decode("utf-8").strip()
    except subprocess.CalledProcessError:
        try:
            # Try Linux command
            output = subprocess.check_output(
                ["hostname", "-I"], stderr=subprocess.DEVNULL
            )
            return output.decode("utf-8").split()[0].strip()
        except (subprocess.CalledProcessError, IndexError):
            pass

    # Fallback to socket method
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return None


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {os.path.basename(sys.argv[0])} <file.ipa> <file.deb>")
        sys.exit(1)

    ipa_file = None
    deb_file = None

    for arg in sys.argv[1:]:
        if arg.endswith(".ipa"):
            ipa_file = arg
        elif arg.endswith(".deb"):
            deb_file = arg
        else:
            print(f"Unknown file type: {arg}")
            sys.exit(1)

    if not ipa_file or not deb_file:
        print("You must provide one .ipa and one .deb file.")
        sys.exit(1)

    out_dir = "/tmp/ipa_patched"
    os.makedirs(out_dir, exist_ok=True)

    ipa_name = os.path.basename(ipa_file)
    output_ipa = os.path.join(out_dir, ipa_name)

    print("[+] Patching IPA with cyan...")
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
    except subprocess.CalledProcessError:
        print("[-] Patch failed.")
        sys.exit(1)
    except FileNotFoundError:
        print(
            "[-] 'cyan' command not found. Please ensure it is installed and in your PATH."
        )
        sys.exit(1)

    print("[+] Patch complete.")

    local_ip = get_local_ip()
    if not local_ip:
        print("Could not detect local IP automatically.")
        local_ip = "YOUR_IP"

    download_link = f"http://{local_ip}:8000/{ipa_name}"

    print()
    print("==========================================")
    print("Download link:")
    print(download_link)
    print("==========================================")
    print()

    # Try to copy to clipboard using pbcopy on macOS
    try:
        if shutil.which("pbcopy"):
            subprocess.run(["pbcopy"], input=download_link.encode("utf-8"), check=True)
            print("[+] Download link copied to clipboard.")
    except Exception:
        pass

    print("[+] Starting HTTP server...")
    print("Press Ctrl+C to stop.")
    print()

    # Start python HTTP server
    try:
        subprocess.run(
            [sys.executable, "-m", "http.server", "8000", "--directory", out_dir]
        )
    except KeyboardInterrupt:
        print("\nStopping HTTP server...")


if __name__ == "__main__":
    main()
