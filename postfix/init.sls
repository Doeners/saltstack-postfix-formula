#!jinja|yaml

{% from "postfix/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('postfix:lookup')) %}

include:
  - postfix._maps

{% if datamap.ensure|default('installed') in ['absent', 'removed'] %}
  {% set pkgensure = 'removed' %}
{% else %}
  {% set pkgensure = 'installed' %}
{% endif %}

postfix:
  pkg:
    - {{ pkgensure }}
    - pkgs:
{% for p in datamap.pkgs %}
      - {{ p }}
{% endfor %}
  service:
    - {{ datamap.service.state|default('running') }}
    - name: {{ datamap.service.name|default('postfix') }}
    - enable: {{ datamap.service.enable|default(True) }}
    - watch:
{% for f in datamap.config.manage %}
      - file: {{ f }}
{% endfor %}


{% for a in salt['pillar.get']('postfix:aliases', []) %}
alias_{{ a.name }}:
  alias:
    - {{ a.ensure|default('present') }}
    - name: {{ a.name }}
    - target: {{ a.target|default('root') }}
{% endfor %}

mailname:
  file:
    - managed
    - name: {{ datamap.config.mailname.path|default('/etc/mailname') }}
    - mode: 644
    - user: root
    - group: root
    - contents: |
        {{ salt['pillar.get']('postfix:settings:mailname', salt['grains.get']('fqdn')) }}

main:
  file:
    - managed
    - name: {{ datamap.config.master.path|default('/etc/postfix/main.cf') }}
    - source: salt://postfix/files/main.cf
    - mode: 640
    - user: root
    - group: postfix
    - template: jinja

master:
  file:
    - managed
    - name: {{ datamap.config.master.path|default('/etc/postfix/master.cf') }}
    - source: salt://postfix/files/master.cf
    - mode: 640
    - user: root
    - group: postfix
    - template: jinja
