---
layout: page
permalink: /team/
title: Team
nav: true
nav_order: 2
---

{% assign data = site.data.people %}

{% for group in data.groups %}
{% assign members = data.people | where: "group", group.id | sort: "order" %}
{% if members.size == 0 %}{% continue %}{% endif %}

{% if group.title %}<h2 class="mades-group-title">{{ group.title }}</h2>{% endif %}

{% case group.style %}
{% when "feature" %}
{% for person in members %}
{% include person-card.liquid person=person style="feature" %}
{% endfor %}
{% when "compact" %}

<div class="mades-alumni-wrap">
  <table class="mades-alumni">
    <thead>
      <tr>
        <th>Name</th>
        <th>Previously</th>
        <th>Year left</th>
        <th>First position after leaving</th>
      </tr>
    </thead>
    <tbody>
{% for person in members %}
{% include person-card.liquid person=person style="compact" %}
{% endfor %}
    </tbody>
  </table>
</div>
{% else %}
<div class="mades-person-grid">
{% for person in members %}
{% include person-card.liquid person=person style="card" %}
{% endfor %}
</div>
{% endcase %}
{% endfor %}
