#!/bin/bash

lid=$1

iblinkinfo  -S `smpquery gi $lid| awk '{print $2}'`

