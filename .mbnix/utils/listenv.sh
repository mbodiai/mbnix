#!/bin/sh

# Define color variables using ANSI escape codes
GOLD=$'\033[38;5;223m'
GOLD_BOLD=$'\033[01;38;5;223m'
RESET=$'\033[0m'
RED=$'\033[31m'
RED_BOLD=$'\033[01;31m'
GREEN=$'\033[32m'
GREEN_BOLD=$'\033[01;32m'
PINK=$'\033[38;5;225m'
PINK_BOLD=$'\033[01;38;5;225m'
YELLOW=$'\033[33m'
YELLOW_BOLD=$'\033[01;33m'
BLUE=$'\033[34m'
BLUE_BOLD=$'\033[01;34m'
MAGENTA=$'\033[35m'
CYAN=$'\033[36m'
LIGHT_CYAN=$'\033[38;5;87m'
LIGHT_CYAN_BOLD=$'\033[01;38;5;87m'
CYAN_BOLD=$'\033[01;36m'
WHITE_BOLD=$'\033[01;37m'
list_envs() {
  mbhelp_env() {
    echo "${PINK_BOLD}Usage:${RESET} ${PINK_BOLD}mb env${RESET} ${GOLD_BOLD}{extras|py|cpp|ros|cuda|all}${RESET}"
    echo
  }

  list_env_py() {
    echo
    echo "${WHITE_BOLD}Python/Conda Environment:${RESET}"
    echo "--------------------------------"

    # Core Python and pip
    echo "${WHITE_BOLD}Python Environment:${RESET}"
    if command -v python3 >/dev/null 2>&1; then
      echo "python: $(which python3) ($(python3 --version))"
    fi
    if command -v pip >/dev/null 2>&1; then
      echo "pip: $(which pip)"
    fi

    # Environment managers
    echo ""
    echo "${CYAN_BOLD}Environment Managers:${RESET}"
    env | grep -E "^(CONDA|VENV|HATCH_ENV)="
    for env_mgr in conda hatch; do
      if command -v "$env_mgr" >/dev/null 2>&1; then
        echo "$env_mgr: $(command -v "$env_mgr")"
      fi
    done

    # Other package managers
    echo ""
    echo "${LIGHT_CYAN}Package Managers:${RESET}"
    env | grep -E "^(PIP_|POETRY_|PDM_|UV_)="
    for pkg_mgr in poetry pdm uv; do
      if command -v "$pkg_mgr" >/dev/null 2>&1; then
        echo "$pkg_mgr: $(which "$pkg_mgr")"
      fi
    done

    # Environment variables
    echo ""
    env | grep -E "^(PYTHONPATH|PYTHON_HOME|PYTHONHOME)="

    # Essential vars summary
    for var in PYTHONPATH VIRTUAL_ENV CONDA_PREFIX CONDA_DEFAULT_ENV PYTHON_HOME HATCH_ENV_ACTIVE HATCH_UV; do
      if printenv "$var" >/dev/null 2>&1; then
        echo "${RED_BOLD}$var${RESET}=$(printenv "$var")"
      else
        echo "$var="
      fi
    done
    echo
  }

  list_env_cpp() {
    echo "${GOLD_BOLD}C++/Build Environment Variables:${RESET}"
    echo "--------------------------------"

    # Compiler settings
    echo "${WHITE_BOLD}Compiler Settings:${RESET}"
    env | grep -E "^(CXX|CC|CFLAGS|CXXFLAGS|LDFLAGS)="

    # Build system
    echo "${WHITE_BOLD}Build System:${RESET}"
    env | grep -E "^(CMAKE|MAKE|NINJA).*="

    # Library paths
    echo "${WHITE_BOLD}Library Paths:${RESET}"
    env | grep -E "^(LD_LIBRARY_PATH|LIBRARY_PATH|PKG_CONFIG_PATH)="

    # Include paths
    echo "${WHITE_BOLD}Include Paths:${RESET}"
    env | grep -E "^(CPATH|INCLUDE|C_INCLUDE_PATH|CPLUS_INCLUDE_PATH)="

    for var in CXX CC CFLAGS CXXFLAGS LDFLAGS CMAKE_PREFIX_PATH LD_LIBRARY_PATH PKG_CONFIG_PATH CPATH; do
      if printenv "$var" >/dev/null 2>&1; then
        echo "${RED_BOLD}$var${RESET}=$(printenv "$var")"
      else
        echo "$var="
      fi
    done
    echo
  }

  list_env_ros() {
    echo "${GREEN_BOLD}ROS2 Environment Variables:${RESET}"
    echo "---------------------------"
    env | grep -iE "ROS|AMENT|COLCON|GAZEBO|CYCLONE"

    for var in ROS_DISTRO ROS_VERSION ROS_PACKAGE_PATH AMENT_PREFIX_PATH; do
      if printenv "$var" >/dev/null 2>&1; then
        echo "${RED_BOLD}$var${RESET}=$(printenv "$var")"
      else
        echo "$var="
      fi
    done
    echo
  }

  list_env_cuda() {
    if [ "$(uname -s)" = "Darwin" ]; then
      return
    fi
    echo "${RED_BOLD}CUDA/GPU Environment Variables:${RESET}"
    echo "--------------------------------"
    # Only show CUDA/GPU specific variables
    env | grep -iE "^(CUDA|NVIDIA|GPU|NCCL|TENSORRT)="

    # Essential CUDA vars summary
    for var in CUDA_HOME CUDA_PATH NVIDIA_DRIVER_CAPABILITIES; do
      if printenv "$var" >/dev/null 2>&1; then
        echo "${RED_BOLD}$var${RESET}=$(printenv "$var")"
      else
        echo "$var="
      fi
    done
    echo "NVIDIA GPU Information:"
    if command -v nvidia-smi >/dev/null 2>&1; then
      nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>/dev/null | sort | uniq || echo "No NVIDIA GPUs found."
    else
      echo "nvidia-smi not found. Unable to query GPU information."
    fi
  }
  list_env_mb() {
    echo "${PINK_BOLD}MB Environment Variables:${RESET}"
    echo "--------------------------------"
    env | grep -iE "MB_"
  }

  list_env_all() {
    echo ""
    list_env_cpp
    echo "---"
    list_env_ros
    echo "---"
    list_env_cuda
    echo "---"
    list_env_py

  }

  case "$1" in
    py | python)
      list_env_py
      ;;
    cpp)
      list_env_cpp
      ;;
    ros)
      list_env_ros
      ;;
    cuda)
      list_env_cuda
      ;;
    all)
      list_env_all
      ;;
    help | -h | --help)
      mbhelp_env
      ;;
    *)
      list_env_all
      list_env_mb
      ;;

  esac
}

# Execute the function with all passed arguments
export list_envs