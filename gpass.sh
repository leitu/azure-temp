#!/bin/bash
date +%s | shasum | base64 | head -c 32 ; echo
