# Interactive 3-D scatter plot of a DEA problem

Plots the DMUs in three dimensions, with each axis and the point colour
set to any input/output variable or any DEA efficiency model (so a
returns-to- scale efficiency such as `"crs"` or `"vrs"` can be used as a
dimension). Efficiencies are computed only when referenced, each at most
once. This plot is always interactive (plotly); it has no static form.

## Usage

``` r
plot_io_3dscatter(
  x,
  dim_x,
  dim_y,
  dim_z,
  color = "crs",
  orientation = "in",
  labels = "none",
  max.overlaps.value = 10,
  transparency = 0.7,
  subtitle = NULL,
  title = NULL,
  ...
)
```

## Arguments

- x:

  A `dea_data` object, or a data frame coerced by
  [`as_dea_data`](https://pomelo64.github.io/deaviz/reference/as_dea_data.md).

- dim_x, dim_y, dim_z:

  Names of the quantities to map to the three axes. Each is either an
  input/output variable name or an efficiency model (`"crs"`, `"vrs"`,
  `"drs"`, `"irs"`, `"fdh"`, `"add"`; a trailing `"_efficiency"` is also
  accepted).

- color:

  Quantity mapping to point colour (same options as the axes; default
  `"crs"`).

- orientation:

  Measurement orientation for efficiency scores, passed to
  [`compute_efficiency`](https://pomelo64.github.io/deaviz/reference/compute_efficiency.md)
  (default `"in"`).

- labels:

  Which DMUs to label: `"none"` (default), `"all"` / `"max.overlaps"`
  (label every point), or the name/id of a single DMU to label only that
  one.

- max.overlaps.value:

  Accepted for API consistency; unused here (default `10`).

- transparency:

  Opacity of the markers/areas, a single number in `[0, 1]` (default
  `0.7`).

- subtitle:

  Optional subtitle shown beneath the title.

- title:

  Optional plot title.

- ...:

  Additional arguments passed to
  [`plotly::plot_ly`](https://rdrr.io/pkg/plotly/man/plot_ly.html).

## Value

A plotly object.

## See also

[`compute_efficiency`](https://pomelo64.github.io/deaviz/reference/compute_efficiency.md)

## Examples

``` r
df <- data.frame(
  dmu  = paste0("D", 1:6),
  i_x1 = c(4, 7, 8, 4, 2, 5),
  i_x2 = c(3, 3, 1, 2, 4, 2),
  o_y  = c(5, 8, 6, 7, 3, 9)
)
plot_io_3dscatter(df, dim_x = "x1", dim_y = "x2", dim_z = "y", color = "crs")

{"x":{"visdat":{"1bb14ee6e807":["function () ","plotlyVisDat"]},"cur_data":"1bb14ee6e807","attrs":{"1bb14ee6e807":{"x":[4,7,8,4,2,5],"y":[3,3,1,2,4,2],"z":[5,8,6,7,3,9],"opacity":0.69999999999999996,"text":["D1","D2","D3","D4","D5","D6"],"mode":"markers","color":[0.69444444444444431,0.634920634920635,1,0.97222222222222243,0.83333333333333326,1],"colors":["#4B0055","#4B0056","#4B0057","#4B0058","#4B0059","#4B005A","#4B035B","#4A055C","#4A085D","#4A0B5E","#4A0D5F","#4A1060","#491261","#491462","#491663","#481864","#481965","#481B65","#471D66","#471E67","#472068","#462169","#46236A","#45246B","#45266C","#44276D","#44296E","#432A6F","#422B70","#422D71","#412E72","#403073","#403173","#3F3274","#3E3375","#3D3576","#3C3677","#3B3778","#3A3979","#393A79","#383B7A","#373C7B","#363E7C","#343F7D","#33407D","#32417E","#30437F","#2F4480","#2D4580","#2B4681","#294882","#274983","#254A83","#234B84","#204C85","#1D4E85","#1A4F86","#165087","#125187","#0C5288","#055389","#005589","#00568A","#00578A","#00588B","#00598C","#005A8C","#005C8D","#005D8D","#005E8E","#005F8E","#00608F","#00618F","#006390","#006490","#006590","#006691","#006791","#006892","#006992","#006A92","#006C93","#006D93","#006E94","#006F94","#007094","#007194","#007295","#007395","#007495","#007596","#007796","#007896","#007996","#007A96","#007B97","#007C97","#007D97","#007E97","#007F97","#008097","#008197","#008298","#008398","#008498","#008598","#008698","#008798","#008898","#008998","#008A98","#008B98","#008C98","#008D98","#008E98","#008F97","#009097","#009197","#009297","#009397","#009497","#009597","#009696","#009796","#009896","#009996","#009A96","#009B95","#009C95","#009D95","#009E94","#009F94","#009F94","#00A093","#00A193","#00A293","#00A392","#00A492","#00A592","#00A691","#00A791","#00A790","#00A890","#00A98F","#00AA8F","#00AB8E","#00AC8E","#00AD8D","#00AD8D","#00AE8C","#00AF8B","#00B08B","#00B18A","#00B28A","#00B289","#00B388","#00B488","#00B587","#00B686","#00B686","#00B785","#00B884","#00B983","#00B983","#00BA82","#00BB81","#00BC80","#00BC7F","#00BD7E","#00BE7E","#00BE7D","#00BF7C","#00C07B","#00C17A","#00C179","#00C278","#00C377","#00C376","#00C475","#00C574","#0FC573","#1CC672","#24C771","#2CC770","#32C86F","#37C96E","#3DC96D","#41CA6C","#46CA6B","#4ACB69","#4ECC68","#52CC67","#56CD66","#5ACD65","#5ECE63","#61CF62","#65CF61","#68D060","#6BD05E","#6ED15D","#72D15C","#75D25B","#78D259","#7BD358","#7ED357","#81D455","#84D454","#87D553","#8AD551","#8CD650","#8FD64E","#92D74D","#95D74C","#98D84A","#9AD849","#9DD947","#A0D946","#A2DA45","#A5DA43","#A8DA42","#AADB40","#ADDB3F","#AFDC3E","#B2DC3C","#B5DC3B","#B7DD3A","#BADD38","#BCDD37","#BFDE36","#C1DE35","#C4DE34","#C6DF32","#C8DF31","#CBDF30","#CDE030","#D0E02F","#D2E02E","#D5E12D","#D7E12D","#D9E12C","#DCE12C","#DEE22B","#E0E22B","#E3E22B","#E5E22B","#E7E22C","#EAE32C","#ECE32C","#EEE32D","#F0E32D","#F2E32E","#F5E32F","#F7E330","#F9E331","#FBE332","#FDE333"],"alpha_stroke":1,"sizes":[10,100],"spans":[1,20],"type":"scatter3d"}},"layout":{"margin":{"b":40,"l":60,"t":25,"r":10},"scene":{"xaxis":{"title":"x1"},"yaxis":{"title":"x2"},"zaxis":{"title":"y"}},"hovermode":"closest","showlegend":false,"legend":{"yanchor":"top","y":0.5}},"source":"A","config":{"modeBarButtonsToAdd":["hoverclosest","hovercompare"],"showSendToCloud":false},"data":[{"x":[4,7,8,4,2,5],"y":[3,3,1,2,4,2],"z":[5,8,6,7,3,9],"opacity":0.69999999999999996,"text":["D1","D2","D3","D4","D5","D6"],"mode":"markers","type":"scatter3d","marker":{"colorbar":{"title":"","ticklen":2},"cmin":0.634920634920635,"cmax":1,"colorscale":[["0","rgba(75,0,85,1)"],["0.0416666666666667","rgba(74,15,96,1)"],["0.0833333333333335","rgba(70,34,105,1)"],["0.125","rgba(64,49,115,1)"],["0.166666666666667","rgba(53,63,124,1)"],["0.208333333333333","rgba(35,75,132,1)"],["0.25","rgba(0,88,139,1)"],["0.291666666666667","rgba(0,100,144,1)"],["0.333333333333333","rgba(0,112,148,1)"],["0.375","rgba(0,124,151,1)"],["0.416666666666667","rgba(0,134,152,1)"],["0.458333333333333","rgba(0,145,151,1)"],["0.5","rgba(0,155,149,1)"],["0.541666666666667","rgba(0,165,146,1)"],["0.583333333333333","rgba(0,174,140,1)"],["0.625","rgba(0,182,134,1)"],["0.666666666666667","rgba(0,190,125,1)"],["0.708333333333333","rgba(24,198,114,1)"],["0.75","rgba(83,204,103,1)"],["0.791666666666667","rgba(120,210,89,1)"],["0.833333333333333","rgba(151,216,75,1)"],["0.875","rgba(178,220,60,1)"],["0.916666666666667","rgba(205,224,48,1)"],["0.958333333333333","rgba(230,226,43,1)"],["1","rgba(253,227,51,1)"]],"showscale":false,"color":[0.69444444444444431,0.634920634920635,1,0.97222222222222243,0.83333333333333326,1],"line":{"colorbar":{"title":"","ticklen":2},"cmin":0.634920634920635,"cmax":1,"colorscale":[["0","rgba(75,0,85,1)"],["0.0416666666666667","rgba(74,15,96,1)"],["0.0833333333333335","rgba(70,34,105,1)"],["0.125","rgba(64,49,115,1)"],["0.166666666666667","rgba(53,63,124,1)"],["0.208333333333333","rgba(35,75,132,1)"],["0.25","rgba(0,88,139,1)"],["0.291666666666667","rgba(0,100,144,1)"],["0.333333333333333","rgba(0,112,148,1)"],["0.375","rgba(0,124,151,1)"],["0.416666666666667","rgba(0,134,152,1)"],["0.458333333333333","rgba(0,145,151,1)"],["0.5","rgba(0,155,149,1)"],["0.541666666666667","rgba(0,165,146,1)"],["0.583333333333333","rgba(0,174,140,1)"],["0.625","rgba(0,182,134,1)"],["0.666666666666667","rgba(0,190,125,1)"],["0.708333333333333","rgba(24,198,114,1)"],["0.75","rgba(83,204,103,1)"],["0.791666666666667","rgba(120,210,89,1)"],["0.833333333333333","rgba(151,216,75,1)"],["0.875","rgba(178,220,60,1)"],["0.916666666666667","rgba(205,224,48,1)"],["0.958333333333333","rgba(230,226,43,1)"],["1","rgba(253,227,51,1)"]],"showscale":false,"color":[0.69444444444444431,0.634920634920635,1,0.97222222222222243,0.83333333333333326,1]}},"frame":null},{"x":[2,8],"y":[1,4],"type":"scatter3d","mode":"markers","opacity":0,"hoverinfo":"none","showlegend":false,"marker":{"colorbar":{"title":"","ticklen":2,"len":0.5,"lenmode":"fraction","y":1,"yanchor":"top"},"cmin":0.634920634920635,"cmax":1,"colorscale":[["0","rgba(75,0,85,1)"],["0.0416666666666667","rgba(74,15,96,1)"],["0.0833333333333335","rgba(70,34,105,1)"],["0.125","rgba(64,49,115,1)"],["0.166666666666667","rgba(53,63,124,1)"],["0.208333333333333","rgba(35,75,132,1)"],["0.25","rgba(0,88,139,1)"],["0.291666666666667","rgba(0,100,144,1)"],["0.333333333333333","rgba(0,112,148,1)"],["0.375","rgba(0,124,151,1)"],["0.416666666666667","rgba(0,134,152,1)"],["0.458333333333333","rgba(0,145,151,1)"],["0.5","rgba(0,155,149,1)"],["0.541666666666667","rgba(0,165,146,1)"],["0.583333333333333","rgba(0,174,140,1)"],["0.625","rgba(0,182,134,1)"],["0.666666666666667","rgba(0,190,125,1)"],["0.708333333333333","rgba(24,198,114,1)"],["0.75","rgba(83,204,103,1)"],["0.791666666666667","rgba(120,210,89,1)"],["0.833333333333333","rgba(151,216,75,1)"],["0.875","rgba(178,220,60,1)"],["0.916666666666667","rgba(205,224,48,1)"],["0.958333333333333","rgba(230,226,43,1)"],["1","rgba(253,227,51,1)"]],"showscale":true,"color":[0.634920634920635,1],"line":{"color":"rgba(255,127,14,1)"}},"z":[3,9],"frame":null}],"highlight":{"on":"plotly_click","persistent":false,"dynamic":false,"selectize":false,"opacityDim":0.20000000000000001,"selected":{"opacity":1},"debounce":0},"shinyEvents":["plotly_hover","plotly_click","plotly_selected","plotly_relayout","plotly_brushed","plotly_brushing","plotly_clickannotation","plotly_doubleclick","plotly_deselect","plotly_afterplot","plotly_sunburstclick"],"base_url":"https://plot.ly"},"evals":[],"jsHooks":[]}
```
