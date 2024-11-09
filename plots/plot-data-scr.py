import matplotlib.pyplot as plt
import numpy as np
import os

# Define the technologies and corresponding colors
technologies = ["Shared-nothing", "Lock-based", "TM", "SCR", "RSS"]
colors = ["#332288", "#CC6677", "#88CCEE", "#44AA99", "#117733"]

# Define the applications and data directory
applications = ["NOP", "SBridge", "Policer", "FW", "NAT", "CL", "PSD"]
workload_types = ["uniform", "single", "zipf", "imc-scr"]
data_dir = "./dats"
output_dir = "./out"  # Directory to save output plots

# Ensure the output directory exists
os.makedirs(output_dir, exist_ok=True)

# Loop over each workload type and create a separate plot
for workload in workload_types:
    # Initialize data structure to store values for each application and technology
    data = {app: [] for app in applications}

    # Load data from .dat files for the current workload type
    for app in applications:
        for tech in technologies:
            # Construct the filename based on the application, technology, and workload type
            filename = os.path.join(data_dir, f"{app.lower()}-{tech.lower().replace(' ', '-')}-{workload}.dat")
            if os.path.exists(filename):
                # Load the data: assuming columns for [xtic, value, error]
                values = np.loadtxt(filename, usecols=[1], delimiter=":")  # Adjust delimiter if necessary
                data[app].append(values)
            else:
                print(f"Warning: File {filename} does not exist.")
                data[app].append([0])  # Placeholder if file is missing

    # Plotting
    num_apps = len(applications)
    bar_width = 0.15  # Width of each bar in a group
    index = np.arange(num_apps)  # The x locations for the applications

    # Create figure and set layout for the current workload type
    fig, axes = plt.subplots(num_apps, 1, figsize=(10, 18), sharex=True)
    fig.suptitle(f'Technologies Comparison - {workload.capitalize()}', fontsize=20)

    # Iterate over each application and plot the histogram bars for each technology
    for i, (app_name, ax) in enumerate(zip(applications, axes)):
        values = data[app_name]
        
        for j, (tech, color) in enumerate(zip(technologies, colors)):
            # Offset each bar within the group by its position
            ax.bar(index[i] + j * bar_width, values[j][0], bar_width, label=tech if i == 0 else "", color=color)

        ax.set_ylabel(app_name, fontsize=14)
        ax.set_ylim(0, 60)
        ax.grid(axis='y', linestyle='--', linewidth=0.5)
        
        if i == 0:
            ax.legend(loc='upper center', ncol=len(technologies), bbox_to_anchor=(0.5, 1.3), fontsize=10)
        if i == num_apps - 1:
            ax.set_xticks(index + (bar_width * (len(technologies) - 1) / 2))
            ax.set_xticklabels(applications, rotation=45)

    # Add x-axis label for the entire plot
    fig.text(0.5, 0.04, 'Applications', ha='center', fontsize=16)
    fig.text(0.04, 0.5, 'Throughput (Mpps)', va='center', rotation='vertical', fontsize=16)

    # Adjust layout to include the title and labels
    plt.tight_layout(rect=[0, 0.04, 1, 0.96])

    # Save each plot as a PDF in the output directory
    output_path = os.path.join(output_dir, f'technologies-comparison-{workload}.pdf')
    plt.savefig(output_path)
    plt.close(fig)  # Close the figure after saving to free up memory

    print(f"Plot saved to {output_path}")
