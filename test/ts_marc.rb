#!/usr/bin/env ruby

# local marc library gets tested
# not already installed one
$LOAD_PATH.unshift("lib")

# encoding: UTF-8

require_relative './test_helper'
require 'test/tc_subfield'
require 'test/tc_datafield'
require 'test/tc_controlfield'
require 'test/tc_record'
require 'test/tc_reader'
require 'test/tc_writer'
require 'test/tc_xml'
