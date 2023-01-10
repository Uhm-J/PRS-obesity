
# Tutorial: Installing Miniconda and Setting Up an Environment

In this tutorial, we will cover the steps for installing Miniconda and creating a new environment for a project. Miniconda is a distribution of the Conda package manager, which allows you to manage your project's dependencies, including Python packages and R packages.

## Step 1: Install Miniconda

1.  Download the Miniconda installer for your operating system from the [Miniconda website](https://docs.conda.io/en/latest/miniconda.html). An option to download directly to the cluster using `wget {link}`.
2.  Open a terminal and navigate to the directory where the installer is located. Preferably in the scratch directory of the cluster.
3.  Run the installer by typing `bash Miniconda3-latest-Linux-x86_64.sh` (replace the file name with the correct name for your system).
4.  Follow the prompts to complete the installation.
5.  Close and reopen your terminal to activate the changes.

## Step 2: Create a New Environment

1.  To create a new environment, type `conda create --name myenv python=3.10` (replace "myenv" with the name of your environment).
2.  Activate the new environment by typing `conda activate myenv`.
3.  To verify that the environment is active, you should see the name of your environment in the terminal prompt, e.g. `(myenv) user@host:~$`.

## Step 3: Install Packages using Conda

 To install packages using conda, you can use the `conda install` command (`-c` specifies the channel to download the package from). Install the following packages to get R and the correct dependencies:

 - `conda install r-base`
  - `conda install -c bioconda bioconductor-biocinstaller`
   - `conda install -c bioconda bioconductor-annotationdbi`
   - `conda install -c anaconda libxml2`
   - `conda install r-xml`
   - `conda install -c bioconda bioconductor-geneplotter`

		 

## Step 4: Install R packages

To install remaining R packages, open R in the terminal by using the command `R` . Install the following packages using `BiocManager::install({package})`. 

 - `tidyr`
 - `dplyr`
 - `utils`
 - `purrr`
 - `affyio` 

Some of these packages will already be installed, as they are depended on by other packages.  

## Conclusion

You should now have Miniconda installed on your system and have created a new environment for your project. You can use the `conda install` command to manage the dependencies for your project, including both Python and R packages. Remember to activate the environment before installing or using packages, as packages installed outside of an environment are not available in that environment.