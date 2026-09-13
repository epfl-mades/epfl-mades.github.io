---
layout: page
permalink: /publications/
title: Publications
nav: true
nav_order: 1
---

<!-- Grouping and ordering come from `scholar.group_by: year` in _config.yml, so there is
     no list of years to maintain here. The pre-v1 page hardcoded years: [2025 ... 2016],
     which silently dropped any paper published in a year nobody had remembered to add. -->

{% include bib_search.liquid %}

<div class="publications">

{% bibliography %}

</div>
