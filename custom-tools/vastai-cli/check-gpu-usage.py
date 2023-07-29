import subprocess
import time
import argparse
import matplotlib.pyplot as plt
import pandas as pd
import os
def parse_gpu_utilization(output_string):
    """
    Parse the output string and extract GPU utilization information into a list of dictionaries.

    Parameters:
        output_string (str): Output string to be parsed.

    Returns:
        List[Dict[str, Union[str, float]]]: List of dictionaries containing ID and GPU utilization information.
    """
    gpu_util_list = []

    lines = output_string.strip().split('\n')[1:]  # Skip header
    for line in lines:
        columns = line.split()
        if len(columns) >= 6:
            gpu_utilization = float(columns[5].rstrip('%'))
            entry = {
                "id": columns[0],
                "gpu_utilization": gpu_utilization,
            }
            gpu_util_list.append(entry)

    return gpu_util_list



def check_gpu_utilization(command="vastai show instances", low_threshold=10, check_interval=10, warning_duration=1800, visualize=False):
    """
    Check the GPU utilization using a command and raise a warning if the utilization remains low for a specified duration.

    Parameters:
        command (str): Command to run and get the GPU utilization.
        low_threshold (float): Threshold below which the GPU utilization is considered low (0 to 100).
        check_interval (int): Time in seconds between each GPU utilization check.
        warning_duration (int): Minimum duration (in seconds) for which the GPU utilization must remain low to raise a warning.
        visualize (bool): If True, visualize the gpu_util_list using matplotlib.

    Returns:
        None
    """
    outputs = []
    low_duration = 0
    while True:
        try:
            # Run the command to get GPU utilization
            _output = subprocess.check_output(command, shell=True, text=True)
            _output = parse_gpu_utilization(_output)
            outputs.extend(_output)
            outputs = outputs[-5:]
            
            df = pd.DataFrame(outputs)
            if len(df) < 1: 
                print('.')
                continue
            out = df.groupby('id').mean('gpu_utilization')
            for id in out.index:
                gpu_util = out.loc[id]['gpu_utilization']
                if gpu_util < low_threshold:
                    if low_duration >= warning_duration:
                        cmd = f'vastai stop {id}'
                        print(f'[Warning] {gpu_util=}| run {cmd} to stop')
                        
                        os.system(cmd)
                    else:
                        low_duration += check_interval
                        print(f'{id} | {gpu_util} | Duration of being low: {low_duration}/{warning_duration} seconds')
                else:
                    low_duration = 0
                    print(f'{id} | {gpu_util}')
        except subprocess.CalledProcessError as e:
            print(f"Error: {e}")

        time.sleep(check_interval)

# Example usage:
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Check GPU utilization and visualize it over time.")
    parser.add_argument("--command", type=str, default="vastai show instances", help="Command to check GPU utilization.")
    parser.add_argument("--low_threshold", type=float, default=10, help="Threshold for low GPU utilization.")
    parser.add_argument("--check_interval", type=int, default=10, help="Time interval (seconds) between each GPU utilization check.")
    parser.add_argument("--warning_duration", type=int, default=1800, help="Minimum duration (seconds) for low GPU utilization to raise a warning.")
    parser.add_argument("--visualize", action="store_true", help="Visualize the GPU utilization over time using matplotlib.")

    args = parser.parse_args()

    check_gpu_utilization(args.command, args.low_threshold, args.check_interval, args.warning_duration, args.visualize)

