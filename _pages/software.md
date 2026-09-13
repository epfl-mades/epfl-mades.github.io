---
layout: page
permalink: /software/
title: Software
nav: true
nav_order: 4
---

<div class="mades-software-grid">
{% for software in site.data.software %}
{% include software-card.liquid software=software %}
{% endfor %}
</div>
