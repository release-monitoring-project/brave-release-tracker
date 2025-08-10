# Brave Release Tracker

This repository provides up-to-date download links (as "releases") for official recent Brave browser builds. 

These are **stable releases** directly from the official Brave GitHub repository.

Note that the check for a newer version occurs **every hour** (UTC time).

## Overview

An automated pipeline fetches the newest Brave browser release for Windows, macOS and Linux for supported architectures (from https://github.com/brave/brave-browser).

If a new Brave release is detected, the pipeline automatically creates a new release with updated download links.

The download links are collected and made available in a structured JSON file for an easy integration into automated tools or for a manual download.
