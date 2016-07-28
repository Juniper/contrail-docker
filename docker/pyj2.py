#!/usr/bin/env python

from jinja2 import Environment, FileSystemLoader
import os
import argparse
import sys
import re


def doc_from_template(template, output, append=False, nvars=None):
    nvars = nvars or {}
    nvars.update(os.environ)
    template_abs_path = os.path.abspath(template)
    template_dir = os.path.dirname(template_abs_path)
    template_file = os.path.basename(template_abs_path)
    jenv = Environment(loader=FileSystemLoader(template_dir),
                         trim_blocks=True)
    template = jenv.get_template(template_file)
    rendered = template.render(**nvars)

    if append:
        mode = 'a'
    else:
        mode = 'w'

    with open(output, mode) as f:
        f.write(rendered)


def main(argv=sys.argv[1:]):
    ap = argparse.ArgumentParser(description="Extract jinja2 template")
    ap.add_argument('-t', '--template', type=str, required=True,
                    help="template file path")
    ap.add_argument('-o', '--output', type=str, required=True,
                    help="output file")
    ap.add_argument('-v', '--variables', nargs='*',
                    help="Variables to be passed to the template")
    ap.add_argument('-a', '--append', action='store_true', default=False)
    args = ap.parse_args()
    if args.variables:
        nvars = {re.split('=', i)[0]: re.split('=', i)[1] for i in args.variables}
    else:
        nvars = None
    doc_from_template(args.template, args.output, append=args.append, nvars=nvars)
    return True

if __name__ == '__main__':
    main(sys.argv[1:])
