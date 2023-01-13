{ dataSourceName, ... }: {
  __inputs = [{
    description = "";
    label = "prometheus";
    name = "${dataSourceName}";
    pluginId = "prometheus";
    pluginName = "Prometheus";
    type = "datasource";
  }];
  __requires = [
    {
      id = "grafana";
      name = "Grafana";
      type = "grafana";
      version = "7.0.3";
    }
    {
      id = "graph";
      name = "Graph";
      type = "panel";
      version = "";
    }
    {
      id = "prometheus";
      name = "Prometheus";
      type = "datasource";
      version = "1.0.0";
    }
    {
      id = "text";
      name = "Text";
      type = "panel";
      version = "";
    }
  ];
  annotations = {
    list = [{
      builtIn = 1;
      datasource = "-- Grafana --";
      enable = true;
      hide = true;
      iconColor = "rgba(0, 211, 255, 1)";
      name = "Annotations & Alerts";
      type = "dashboard";
    }];
  };
  editable = true;
  gnetId = null;
  graphTooltip = 1;
  id = null;
  iteration = 1591876836041;
  links = [ ];
  panels = [
    {
      content = ''
        # zrepl Prometheus Metrics

        zrepl exposes Prometheus metrics and ships with this Grafana dashboard.
        The exported metrics are suitable for health checks:

        * The log should generally be warning & error-free
          * The `Log Messages that require attention` graph visualizes log message at levels that generally indicate problems.
        * The number of goroutines should not grow unboundedly over time.
          * During replication, the number of goroutines can be way higher than during idle time.
          * If the goroutine count grows with each replication, there is clearly a goroutine leak. Please open a bug report.
        * Memory consumption should not grow unboundedly over time.
          * Note that the Go runtime pre-allocates some of its heap from the OS.
          * zrepl actually uses much less memory than allocated from the OS.
          * Since Go 1.11, Go pre-allocates more aggressively.
        * Monitor that some data is replicated, although that metric does not guarantee that replication was successful.

        **In general, note that the exported metrics are not stable unless declared otherwise.**'';
      datasource = "${dataSourceName}";
      fieldConfig = {
        defaults = { custom = { }; };
        overrides = [ ];
      };
      gridPos = {
        h = 10;
        w = 24;
        x = 0;
        y = 0;
      };
      id = 35;
      mode = "markdown";
      title = "Panel Title";
      type = "text";
    }
    {
      cacheTimeout = null;
      colorBackground = true;
      colorPostfix = false;
      colorPrefix = false;
      colorValue = false;
      colors = [ "#bf1b00" "#508642" "#bf1b00" ];
      datasource = "${dataSourceName}";
      description = "Number of filesystems that failed replications";
      format = "none";
      gauge = {
        maxValue = 100;
        minValue = 0;
        show = false;
        thresholdLabels = false;
        thresholdMarkers = true;
      };
      gridPos = {
        h = 3;
        w = 24;
        x = 0;
        y = 10;
      };
      id = 50;
      interval = null;
      links = [ ];
      mappingType = 1;
      mappingTypes = [
        {
          name = "value to text";
          value = 1;
        }
        {
          name = "range to text";
          value = 2;
        }
      ];
      maxDataPoints = 100;
      nullPointMode = "connected";
      nullText = null;
      postfix = "";
      postfixFontSize = "50%";
      prefix = "";
      prefixFontSize = "50%";
      rangeMaps = [{
        from = "";
        text = "";
        to = "";
      }];
      repeat = "zrepl_job_name";
      repeatDirection = "h";
      scopedVars = {
        zrepl_job_name = {
          selected = false;
          text = "desktop_to_homesrv";
          value = "desktop_to_homesrv";
        };
      };
      sparkline = {
        fillColor = "rgba(31, 118, 189, 0.18)";
        full = true;
        lineColor = "rgb(31, 120, 193)";
        show = true;
      };
      # tableColumn = "__name__";
      targets = [{
        expr = ''
          zrepl_replication_filesystem_errors{job="zrepl",zrepl_job="$zrepl_job_name"}'';
        format = "time_series";
        groupBy = [
          {
            params = [ "$__interval" ];
            type = "time";
          }
          {
            params = [ "null" ];
            type = "fill";
          }
        ];
        instant = true;
        interval = "";
        intervalFactor = 1;
        legendFormat = "";
        orderByTime = "ASC";
        policy = "default";
        refId = "A";
        resultFormat = "time_series";
        select = [[
          {
            params = [ "value" ];
            type = "field";
          }
          {
            params = [ ];
            type = "mean";
          }
        ]];
        tags = [ ];
      }];
      thresholds = "0,1";
      title = "Failed replications $zrepl_job_name";
      transparent = false;
      type = "singlestat";
      valueFontSize = "80%";
      valueMaps = [
        {
          op = "=";
          text = "All failed";
          value = "-1";
        }
        {
          op = "=";
          text = "All OK";
          value = "0";
        }
      ];
      valueName = "avg";
    }
    {
      aliasColors = { };
      bars = false;
      dashLength = 10;
      dashes = false;
      datasource = "${dataSourceName}";
      fieldConfig = {
        defaults = { custom = { }; };
        overrides = [ ];
      };
      fill = 1;
      fillGradient = 0;
      gridPos = {
        h = 4;
        w = 12;
        x = 0;
        y = 13;
      };
      hiddenSeries = false;
      id = 48;
      legend = {
        avg = false;
        current = false;
        max = false;
        min = false;
        show = true;
        total = false;
        values = false;
      };
      lines = true;
      linewidth = 1;
      links = [ ];
      nullPointMode = "null";
      options = { dataLinks = [ ]; };
      percentage = false;
      pointradius = 5;
      points = false;
      renderer = "flot";
      seriesOverrides = [ ];
      spaceLength = 10;
      stack = true;
      steppedLine = false;
      targets = [{
        expr = "sgn(zrepl_start_time{job='zrepl'})";
        format = "time_series";
        interval = "";
        intervalFactor = 1;
        legendFormat = "{{instance}}@version={{raw}}";
        refId = "A";
      }];
      thresholds = [ ];
      timeFrom = null;
      timeRegions = [ ];
      timeShift = null;
      title = "zrepl Instances Up";
      tooltip = {
        shared = true;
        sort = 0;
        value_type = "individual";
      };
      type = "graph";
      xaxis = {
        buckets = null;
        mode = "time";
        name = null;
        show = true;
        values = [ ];
      };
      yaxes = [
        {
          format = "short";
          label = null;
          logBase = 1;
          max = "5";
          min = "0";
          show = true;
        }
        {
          format = "short";
          label = null;
          logBase = 1;
          max = null;
          min = null;
          show = true;
        }
      ];
      yaxis = {
        align = false;
        alignLevel = null;
      };
    }
    {
      aliasColors = { };
      bars = false;
      dashLength = 10;
      dashes = false;
      datasource = "${dataSourceName}";
      fieldConfig = {
        defaults = { custom = { }; };
        overrides = [ ];
      };
      fill = 1;
      fillGradient = 0;
      gridPos = {
        h = 5;
        w = 12;
        x = 12;
        y = 13;
      };
      hiddenSeries = false;
      id = 44;
      legend = {
        avg = false;
        current = false;
        max = false;
        min = false;
        show = true;
        total = false;
        values = false;
      };
      lines = true;
      linewidth = 1;
      links = [ ];
      nullPointMode = "null";
      options = { dataLinks = [ ]; };
      percentage = false;
      pointradius = 5;
      points = false;
      renderer = "flot";
      seriesOverrides = [ ];
      spaceLength = 10;
      stack = false;
      steppedLine = false;
      targets = [{
        expr = "zrepl_trace_active_tasks";
        format = "time_series";
        intervalFactor = 1;
        refId = "A";
      }];
      thresholds = [ ];
      timeFrom = null;
      timeRegions = [ ];
      timeShift = null;
      title =
        "active tasks tracked by the zrepl trace module (should not grow unboundedly)";
      tooltip = {
        shared = true;
        sort = 0;
        value_type = "individual";
      };
      type = "graph";
      xaxis = {
        buckets = null;
        mode = "time";
        name = null;
        show = true;
        values = [ ];
      };
      yaxes = [
        {
          format = "short";
          label = null;
          logBase = 1;
          max = null;
          min = null;
          show = true;
        }
        {
          format = "short";
          label = null;
          logBase = 1;
          max = null;
          min = null;
          show = true;
        }
      ];
      yaxis = {
        align = false;
        alignLevel = null;
      };
    }
    {
      aliasColors = { };
      bars = true;
      dashLength = 10;
      dashes = false;
      datasource = "${dataSourceName}";
      fieldConfig = {
        defaults = { custom = { }; };
        overrides = [ ];
      };
      fill = 1;
      fillGradient = 0;
      gridPos = {
        h = 5;
        w = 12;
        x = 0;
        y = 17;
      };
      hiddenSeries = false;
      id = 42;
      legend = {
        alignAsTable = false;
        avg = false;
        current = false;
        max = false;
        min = false;
        show = true;
        total = false;
        values = false;
      };
      lines = false;
      linewidth = 1;
      links = [ ];
      nullPointMode = "null";
      options = { dataLinks = [ ]; };
      percentage = false;
      pointradius = 5;
      points = false;
      renderer = "flot";
      seriesOverrides = [{
        alias = "/replicated bytes in last.*/";
        yaxis = 2;
      }];
      spaceLength = 10;
      stack = false;
      steppedLine = false;
      targets = [{
        expr =
          "sum(increase(zrepl_replication_bytes_replicated{job='zrepl'}[1d])) by (zrepl_job)";
        format = "time_series";
        hide = false;
        instant = false;
        interval = "1d";
        intervalFactor = 1;
        legendFormat = "zrepl_job={{zrepl_job}}";
        refId = "B";
      }];
      thresholds = [ ];
      timeFrom = null;
      timeRegions = [ ];
      timeShift = null;
      title = "Daily Replication Data Volume";
      tooltip = {
        shared = true;
        sort = 0;
        value_type = "individual";
      };
      type = "graph";
      xaxis = {
        buckets = null;
        mode = "time";
        name = null;
        show = true;
        values = [ ];
      };
      yaxes = [
        {
          format = "bytes";
          label = null;
          logBase = 1;
          max = null;
          min = "0";
          show = true;
        }
        {
          format = "bytes";
          label = null;
          logBase = 1;
          max = null;
          min = null;
          show = false;
        }
      ];
      yaxis = {
        align = false;
        alignLevel = null;
      };
    }
    {
      aliasColors = { };
      bars = false;
      dashLength = 10;
      dashes = false;
      datasource = "${dataSourceName}";
      fieldConfig = {
        defaults = { custom = { }; };
        overrides = [ ];
      };
      fill = 1;
      fillGradient = 0;
      gridPos = {
        h = 4;
        w = 12;
        x = 12;
        y = 18;
      };
      hiddenSeries = false;
      id = 22;
      legend = {
        avg = false;
        current = false;
        max = false;
        min = false;
        show = true;
        total = false;
        values = false;
      };
      lines = true;
      linewidth = 1;
      links = [ ];
      nullPointMode = "null";
      options = { dataLinks = [ ]; };
      percentage = false;
      pointradius = 5;
      points = false;
      renderer = "flot";
      seriesOverrides = [ ];
      spaceLength = 10;
      stack = false;
      steppedLine = false;
      targets = [{
        expr =
          "increase(zrepl_daemon_log_entries{job='zrepl',level=~'warn|error'}[1m])";
        format = "time_series";
        intervalFactor = 1;
        refId = "A";
      }];
      thresholds = [ ];
      timeFrom = null;
      timeRegions = [ ];
      timeShift = null;
      title = "Log Messages that require attention";
      tooltip = {
        shared = true;
        sort = 0;
        value_type = "individual";
      };
      type = "graph";
      xaxis = {
        buckets = null;
        mode = "time";
        name = null;
        show = true;
        values = [ ];
      };
      yaxes = [
        {
          format = "short";
          label = null;
          logBase = 1;
          max = null;
          min = "0";
          show = true;
        }
        {
          format = "short";
          label = null;
          logBase = 1;
          max = null;
          min = null;
          show = true;
        }
      ];
      yaxis = {
        align = false;
        alignLevel = null;
      };
    }
    {
      aliasColors = { };
      bars = false;
      dashLength = 10;
      dashes = false;
      datasource = "${dataSourceName}";
      fieldConfig = {
        defaults = { custom = { }; };
        overrides = [ ];
      };
      fill = 1;
      fillGradient = 0;
      gridPos = {
        h = 5;
        w = 12;
        x = 0;
        y = 22;
      };
      hiddenSeries = false;
      id = 33;
      legend = {
        avg = false;
        current = false;
        max = false;
        min = false;
        show = true;
        total = false;
        values = false;
      };
      lines = true;
      linewidth = 1;
      links = [ ];
      nullPointMode = "null";
      options = { dataLinks = [ ]; };
      percentage = false;
      pointradius = 5;
      points = false;
      renderer = "flot";
      seriesOverrides = [{
        alias = "/replicated bytes in last.*/";
        yaxis = 2;
      }];
      spaceLength = 10;
      stack = false;
      steppedLine = false;
      targets = [
        {
          expr =
            "sum(rate(zrepl_replication_bytes_replicated{job='zrepl'}[10m])) by (zrepl_job)";
          format = "time_series";
          hide = false;
          interval = "";
          intervalFactor = 1;
          legendFormat =
            "replication data rate in last 10min zrepl_job={{zrepl_job}}te zrepl_job={{zrepl_job}}";
          refId = "A";
        }
        {
          expr =
            "sum(increase(zrepl_replication_bytes_replicated{job='zrepl'}[10m])) by (zrepl_job)";
          format = "time_series";
          hide = false;
          interval = "";
          intervalFactor = 1;
          legendFormat =
            "replicated bytes in last 10min zrepl_job={{zrepl_job}}";
          refId = "B";
        }
      ];
      thresholds = [ ];
      timeFrom = null;
      timeRegions = [ ];
      timeShift = null;
      title = "Replication Data Rate and Volume(over last 10min)";
      tooltip = {
        shared = true;
        sort = 0;
        value_type = "individual";
      };
      type = "graph";
      xaxis = {
        buckets = null;
        mode = "time";
        name = null;
        show = true;
        values = [ ];
      };
      yaxes = [
        {
          format = "Bps";
          label = null;
          logBase = 1;
          max = null;
          min = null;
          show = true;
        }
        {
          format = "bytes";
          label = null;
          logBase = 1;
          max = null;
          min = null;
          show = true;
        }
      ];
      yaxis = {
        align = false;
        alignLevel = null;
      };
    }
    {
      aliasColors = { };
      bars = false;
      dashLength = 10;
      dashes = false;
      datasource = "${dataSourceName}";
      fieldConfig = {
        defaults = { custom = { }; };
        overrides = [ ];
      };
      fill = 1;
      fillGradient = 0;
      gridPos = {
        h = 5;
        w = 12;
        x = 12;
        y = 22;
      };
      hiddenSeries = false;
      id = 23;
      legend = {
        avg = false;
        current = false;
        max = false;
        min = false;
        show = true;
        total = false;
        values = false;
      };
      lines = true;
      linewidth = 1;
      links = [ ];
      nullPointMode = "null";
      options = { dataLinks = [ ]; };
      percentage = false;
      pointradius = 5;
      points = false;
      renderer = "flot";
      seriesOverrides = [ ];
      spaceLength = 10;
      stack = false;
      steppedLine = false;
      targets = [{
        expr = ''
          sum(increase(zrepl_daemon_log_entries{job='zrepl',zrepl_job=~"^[^_].*"}[1m])) by (instance,zrepl_job)'';
        format = "time_series";
        intervalFactor = 1;
        refId = "A";
      }];
      thresholds = [ ];
      timeFrom = null;
      timeRegions = [ ];
      timeShift = null;
      title = "Log Activity (without internal jobs)";
      tooltip = {
        shared = true;
        sort = 0;
        value_type = "individual";
      };
      type = "graph";
      xaxis = {
        buckets = null;
        mode = "time";
        name = null;
        show = true;
        values = [ ];
      };
      yaxes = [
        {
          format = "short";
          label = null;
          logBase = 1;
          max = null;
          min = "0";
          show = true;
        }
        {
          format = "short";
          label = null;
          logBase = 1;
          max = null;
          min = null;
          show = true;
        }
      ];
      yaxis = {
        align = false;
        alignLevel = null;
      };
    }
    {
      aliasColors = { };
      bars = false;
      dashLength = 10;
      dashes = false;
      datasource = "${dataSourceName}";
      fieldConfig = {
        defaults = { custom = { }; };
        overrides = [ ];
      };
      fill = 1;
      fillGradient = 0;
      gridPos = {
        h = 5;
        w = 12;
        x = 0;
        y = 27;
      };
      hiddenSeries = false;
      id = 41;
      legend = {
        avg = false;
        current = false;
        max = false;
        min = false;
        rightSide = false;
        show = true;
        total = false;
        values = false;
      };
      lines = true;
      linewidth = 1;
      links = [ ];
      nullPointMode = "null";
      options = { dataLinks = [ ]; };
      percentage = false;
      pointradius = 5;
      points = false;
      renderer = "flot";
      seriesOverrides = [ ];
      spaceLength = 10;
      stack = false;
      steppedLine = false;
      targets = [{
        expr = "go_memstats_alloc_bytes{job='zrepl'}";
        format = "time_series";
        intervalFactor = 1;
        refId = "A";
      }];
      thresholds = [ ];
      timeFrom = null;
      timeRegions = [ ];
      timeShift = null;
      title = "Go Memory Allocations (should not grow unboundedly)";
      tooltip = {
        shared = true;
        sort = 0;
        value_type = "individual";
      };
      type = "graph";
      xaxis = {
        buckets = null;
        mode = "time";
        name = null;
        show = true;
        values = [ ];
      };
      yaxes = [
        {
          format = "bytes";
          label = null;
          logBase = 1;
          max = null;
          min = null;
          show = true;
        }
        {
          format = "short";
          label = "";
          logBase = 1;
          max = null;
          min = null;
          show = true;
        }
      ];
      yaxis = {
        align = false;
        alignLevel = null;
      };
    }
    {
      aliasColors = { };
      bars = false;
      dashLength = 10;
      dashes = false;
      datasource = "${dataSourceName}";
      fieldConfig = {
        defaults = { custom = { }; };
        overrides = [ ];
      };
      fill = 1;
      fillGradient = 0;
      gridPos = {
        h = 5;
        w = 12;
        x = 12;
        y = 27;
      };
      hiddenSeries = false;
      id = 47;
      legend = {
        avg = false;
        current = false;
        max = false;
        min = false;
        show = true;
        total = false;
        values = false;
      };
      lines = true;
      linewidth = 1;
      links = [ ];
      nullPointMode = "null";
      options = { dataLinks = [ ]; };
      percentage = false;
      pointradius = 5;
      points = false;
      renderer = "flot";
      seriesOverrides = [ ];
      spaceLength = 10;
      stack = false;
      steppedLine = false;
      targets = [{
        expr = "zrepl_endpoint_abstractions_cache_entry_count";
        format = "time_series";
        intervalFactor = 1;
        refId = "A";
      }];
      thresholds = [ ];
      timeFrom = null;
      timeRegions = [ ];
      timeShift = null;
      title =
        "zfs abstractions cache entry count (should not be zero and not grow unboundedly)";
      tooltip = {
        shared = true;
        sort = 0;
        value_type = "individual";
      };
      type = "graph";
      xaxis = {
        buckets = null;
        mode = "time";
        name = null;
        show = true;
        values = [ ];
      };
      yaxes = [
        {
          format = "short";
          label = null;
          logBase = 1;
          max = null;
          min = null;
          show = true;
        }
        {
          format = "short";
          label = null;
          logBase = 1;
          max = null;
          min = null;
          show = true;
        }
      ];
      yaxis = {
        align = false;
        alignLevel = null;
      };
    }
    {
      aliasColors = { };
      bars = false;
      dashLength = 10;
      dashes = false;
      datasource = "${dataSourceName}";
      fieldConfig = {
        defaults = { custom = { }; };
        overrides = [ ];
      };
      fill = 1;
      fillGradient = 0;
      gridPos = {
        h = 5;
        w = 12;
        x = 0;
        y = 32;
      };
      hiddenSeries = false;
      id = 17;
      legend = {
        avg = false;
        current = false;
        max = false;
        min = false;
        show = true;
        total = false;
        values = false;
      };
      lines = true;
      linewidth = 1;
      links = [ ];
      nullPointMode = "null";
      options = { dataLinks = [ ]; };
      percentage = false;
      pointradius = 5;
      points = false;
      renderer = "flot";
      seriesOverrides = [ ];
      spaceLength = 10;
      stack = false;
      steppedLine = false;
      targets = [{
        expr = "go_memstats_sys_bytes{job='zrepl'}";
        format = "time_series";
        hide = false;
        intervalFactor = 1;
        refId = "A";
      }];
      thresholds = [ ];
      timeFrom = null;
      timeRegions = [ ];
      timeShift = null;
      title =
        "Memory Allocated by the Go runtime from the OS (should not grow unboundedly)";
      tooltip = {
        shared = true;
        sort = 0;
        value_type = "individual";
      };
      type = "graph";
      xaxis = {
        buckets = null;
        mode = "time";
        name = null;
        show = true;
        values = [ ];
      };
      yaxes = [
        {
          format = "bytes";
          label = null;
          logBase = 1;
          max = null;
          min = "0";
          show = true;
        }
        {
          format = "short";
          label = null;
          logBase = 1;
          max = null;
          min = null;
          show = true;
        }
      ];
      yaxis = {
        align = false;
        alignLevel = null;
      };
    }
    {
      aliasColors = { };
      bars = false;
      dashLength = 10;
      dashes = false;
      datasource = "${dataSourceName}";
      fieldConfig = {
        defaults = { custom = { }; };
        overrides = [ ];
      };
      fill = 1;
      fillGradient = 0;
      gridPos = {
        h = 5;
        w = 12;
        x = 0;
        y = 37;
      };
      hiddenSeries = false;
      id = 19;
      legend = {
        avg = false;
        current = false;
        max = false;
        min = false;
        show = true;
        total = false;
        values = false;
      };
      lines = true;
      linewidth = 1;
      links = [ ];
      nullPointMode = "null";
      options = { dataLinks = [ ]; };
      percentage = false;
      pointradius = 5;
      points = false;
      renderer = "flot";
      seriesOverrides = [ ];
      spaceLength = 10;
      stack = false;
      steppedLine = false;
      targets = [{
        expr = "go_goroutines{job='zrepl'}";
        format = "time_series";
        intervalFactor = 1;
        refId = "A";
      }];
      thresholds = [ ];
      timeFrom = null;
      timeRegions = [ ];
      timeShift = null;
      title = "number of goroutines (should not grow unboundedly)";
      tooltip = {
        shared = true;
        sort = 0;
        value_type = "individual";
      };
      type = "graph";
      xaxis = {
        buckets = null;
        mode = "time";
        name = null;
        show = true;
        values = [ ];
      };
      yaxes = [
        {
          format = "short";
          label = null;
          logBase = 1;
          max = null;
          min = "0";
          show = true;
        }
        {
          format = "short";
          label = null;
          logBase = 1;
          max = null;
          min = null;
          show = true;
        }
      ];
      yaxis = {
        align = false;
        alignLevel = null;
      };
    }
  ];
  refresh = "5s";
  schemaVersion = 25;
  style = "dark";
  tags = [ ];
  templating = {
    list = [
      {
        allValue = null;
        current = { };
        datasource = "${dataSourceName}";
        definition = "";
        hide = 0;
        includeAll = false;
        label = "Prometheus Job Name";
        multi = false;
        name = "prom_job_name";
        options = [ ];
        query = "label_values(up, job)";
        refresh = 1;
        regex = "";
        skipUrlSync = false;
        sort = 1;
        tagValuesQuery = "";
        tags = [ ];
        tagsQuery = "";
        type = "query";
        useTags = false;
      }
      {
        allValue = null;
        current = {
          text = "All";
          value = [ "$__all" ];
        };
        datasource = "${dataSourceName}";
        definition = ''
          label_values(zrepl_replication_filesystem_errors{job="zrepl"}, zrepl_job)'';
        hide = 2;
        includeAll = true;
        label = "Zrepl Job Name";
        multi = true;
        name = "zrepl_job_name";
        options = [ ];
        query = ''
          label_values(zrepl_replication_filesystem_errors{job="zrepl"}, zrepl_job)'';
        refresh = 1;
        regex = "";
        skipUrlSync = false;
        sort = 1;
        tagValuesQuery = "";
        tags = [ ];
        tagsQuery = "";
        type = "query";
        useTags = false;
      }
    ];
  };
  time = {
    from = "now-2d";
    to = "now";
  };
  timepicker = {
    refresh_intervals = [ "10s" "30s" "1m" "5m" "15m" "30m" "1h" "2h" "1d" ];
    time_options = [ "5m" "15m" "1h" "6h" "12h" "24h" "2d" "7d" "30d" ];
  };
  timezone = "";
  title = "${dataSourceName}-zrepl";
  uid = "${dataSourceName}-zrepl";
  version = 8;
}
