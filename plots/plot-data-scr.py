import matplotlib.pyplot as plt
import numpy as np
import os

from pdfCropMargins import crop

# Define the technologies and corresponding colors
# technologies = ["SN", "Lock-based", "TM", "SCR", "RSS"]
technologies: list[str] = ["SN", "SCR", "RSS", "TM", "Locks"]
colors = ["#332288", "#CC6677", "#88CCEE", "#44AA99", "#117733"]

# Define the applications and data directory
applications: list[str] = ["NOP", "SBridge", "Pol", "FW", "NAT", "CL"]
workload_types: list[str] = ["uniform", "single", "zipf", "imc-scr", "caida"]
graph_types: list[str] = ["mpps", "gbps", "gbps_scr"]
pkt_sizes: list[int] = [64]

data_dir = "./dats"
output_dir = "./out"  # Directory to save output plots

# Ensure the output directory exists
os.makedirs(output_dir, exist_ok=True)

for pkt_size in pkt_sizes:
    for graph_type in graph_types:
        # Loop over each workload type and create a separate plot
        for workload in workload_types:
            # Initialize data structure to store values for each application and technology
            data = {app: [] for app in applications}

            # Load data from .dat files for the current workload type
            for app in applications:
                for tech in technologies:
                    if tech.lower() != "scr" and graph_type.lower() == "gbps_scr":
                        filename = os.path.join(data_dir, f"{app.lower()}-{tech.lower().replace(' ', '-')}-{workload}-{pkt_size}B_{graph_type.replace('_scr', '')}.dat")
                    else:    
                        # Construct the filename based on the application, technology, and workload type
                        filename = os.path.join(data_dir, f"{app.lower()}-{tech.lower().replace(' ', '-')}-{workload}-{pkt_size}B_{graph_type}.dat")

                    if os.path.exists(filename):
                        # Load the data: assuming the second column contains the median values for each core
                        median_values = np.loadtxt(filename, usecols=[1], skiprows=1)  # Skip header row
                        data[app].append(median_values)  # Use all median values (one per core)
                    else:
                        print(f"Warning: File {filename} does not exist.")
                        data[app].append(np.zeros(8))  # Placeholder if file is missing (assuming 8 cores)

            # Plotting
            num_apps = len(applications)
            bar_width = 0.15  # Width of each bar group
            num_cores = len(data[applications[0]][0])  # Assuming each data file has the same number of cores
            index = np.arange(num_cores)  # The x locations for the cores

            # Create figure and set layout for the current workload type
            fig, axes = plt.subplots(num_apps, 1, figsize=(12, 18), sharex=True)
            fig.suptitle(f'Technologies Comparison {graph_type.capitalize()} - {workload.capitalize()}, {pkt_size}B', fontsize=20, y=0.91)

            # Set default color cycle
            # colors = plt.get_cmap("tab10").colors

            # Iterate over each application and plot the histogram bars for each technology across all cores
            for i, (app_name, ax) in enumerate(zip(applications, axes)):
                # Plot each technology for all cores
                for j, tech in enumerate(technologies):
                    # Offset each bar within the group by its position
                    ax.bar(index + j * bar_width, data[app_name][j], bar_width, color=colors[j])

                if graph_type.lower() == "gbps":
                    ax.set_ylim(0, 100) # Cap y-limit at 100 Gbps
                    
                # ax.set_ylim(0, 144.8)  # Cap y-limit at 144.8 Mpps
                ax.grid(axis='y', linestyle='--', linewidth=0.5)
                
                # Set x-ticks with labels on each subplot
                ax.set_xticks(index + (bar_width * (len(technologies) - 1) / 2))
                ax.set_xticklabels([f'{core + 1} cores' for core in index])

                # Move application name to the right side, rotated by 90 degrees
                ax.annotate(app_name, xy=(1.02, 0.5), xycoords='axes fraction', ha='left', va='center', 
                            fontsize=12, rotation=90)

            # Set the legend once, slightly below the title to avoid overlap
            fig.legend(technologies, loc="upper center", ncol=len(technologies), fontsize=10, bbox_to_anchor=(0.5, 0.89))

            # Add y-axis label for throughput, with additional padding
            fig.text(0.055, 0.5, f'Throughput ({graph_type.capitalize()})', va='center', rotation='vertical', fontsize=14)

            # Add x-axis label for the entire plot
            fig.text(0.5, 0.055, 'Number of Cores', ha='center', fontsize=14)

            # Adjust layout to ensure no overlaps and bring legend closer to the subplots
            plt.tight_layout(rect=[0.06, 0.06, 1, 0.90])

            fig.subplots_adjust(hspace=0.1)

            # Save each plot as a PDF in the output directory
            output_path = os.path.join(output_dir, f'technologies-comparison-{workload}-{pkt_size}B-{graph_type}.pdf')
            plt.savefig(output_path)
            plt.close(fig)  # Close the figure after saving to free up memory

            crop(["-u", "-o", f'{output_path.rstrip(".pdf")}_cropped.pdf', f"{output_path}"])
            os.replace(f'{output_path.rstrip(".pdf")}_cropped.pdf', f"{output_path}")

            print(f"Plot saved to {output_path}")