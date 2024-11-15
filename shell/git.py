import os
import subprocess
import sys
import requests
import click
from rich import print
from rich.prompt import Prompt

# Set up GitHub configuration with an environment variable for the token
def get_github_token():
    token = os.getenv("GITHUB_TOKEN")
    if not token:
        token = Prompt.ask("Enter your GitHub token (will not be stored):")
    return token

# Initialize a Git repository if one does not already exist
def initialize_git_repo(repo_path):
    if not os.path.isdir(os.path.join(repo_path, ".git")):
        subprocess.run(["git", "init"], cwd=repo_path)
        print(f"[green]Initialized Git repository in {repo_path}[/green]")

# Create a basic flake.nix file if it does not exist
def create_flake_file(repo_path, repo_name):
    flake_nix_path = os.path.join(repo_path, "flake.nix")
    if not os.path.exists(flake_nix_path):
        with open(flake_nix_path, "w") as f:
            f.write(f"""
{{
  description = "Nix Flake for {repo_name}";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = {{ self, nixpkgs }}:
    let
      pkgs = import nixpkgs {{ system = "x86_64-linux"; }};
    in
    {{
      packages.default = pkgs.hello;
      devShells.default = pkgs.mkShell {{
        buildInputs = [ pkgs.hello ];
      }};
    }};
}}
            """)
        print(f"[green]Created default flake.nix for {repo_name}[/green]")

# Create a GitHub repository through the GitHub API
def create_github_repo(repo_name, token):
    url = "https://api.github.com/user/repos"
    headers = {"Authorization": f"token {token}"}
    data = {"name": repo_name, "private": False}

    response = requests.post(url, headers=headers, json=data)
    if response.status_code == 201:
        print(f"[green]Created repository https://github.com/{GITHUB_USER}/{repo_name}[/green]")
    else:
        print("[red]Failed to create repository[/red]:", response.json())
        sys.exit(1)

# Add remote, commit, and push the code to GitHub
def add_remote_and_push(repo_path, repo_name):
    remote_url = f"https://github.com/{GITHUB_USER}/{repo_name}.git"
    subprocess.run(["git", "remote", "add", "origin", remote_url], cwd=repo_path)
    subprocess.run(["git", "add", "."], cwd=repo_path)
    subprocess.run(["git", "commit", "-m", "Initial commit with Nix Flake setup"], cwd=repo_path)
    subprocess.run(["git", "push", "-u", "origin", "main"], cwd=repo_path)
    print("[green]Pushed code to GitHub[/green]")

# Main function that uses rich-click to handle the command-line arguments
@click.command()
@click.argument("repo_path", type=click.Path(exists=True))
def main(repo_path):
    # Extract GitHub username from environment or prompt if needed
    global GITHUB_USER
    GITHUB_USER = Prompt.ask("Enter your GitHub username")

    # Get GitHub token securely
    token = get_github_token()

    # Get the repo name from the path
    repo_name = os.path.basename(repo_path)

    # Initialize Git repo and flake.nix if needed
    initialize_git_repo(repo_path)
    create_flake_file(repo_path, repo_name)

    # Create GitHub repository and push code
    create_github_repo(repo_name, token)
    add_remote_and_push(repo_path, repo_name)

    # Output the Flake URL for easy access
    flake_url = f"git+https://github.com/{GITHUB_USER}/{repo_name}"
    print(f"[cyan]Nix Flake URL: {flake_url}[/cyan]")
    print("To use the Flake, run:")
    print(f"  nix build {flake_url}")
    print(f"  nix develop {flake_url}")

if __name__ == "__main__":
    main()