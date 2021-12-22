# ASCEND
Author Self-Citation lEarNing Detector

ASCEND is a project about looking for self-referencing in the scientific literature. The goal is to compute statistics about self-referencing in the literature, and then train some machine learning algorithms to try to infer which authors of an article will also appear within the references.

## Installation
Try to run the R file ascend.R. If there are errors with the installation of some dependencies, try the following depending on which dependency returns an error:
#### curl
If curl is not found on your system, try installing either:
* deb: libcurl4-openssl-dev (Debian, Ubuntu, etc)
* rpm: libcurl-devel (Fedora, CentOS, RHEL)
* csw: libcurl_dev (Solaris)

## Usage
Just run ascend.R (in installation folder):
```
Rscript ascend.R
```