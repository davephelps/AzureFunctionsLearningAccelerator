
# Challenge 5.2 - Dashboards and Workbooks

Creating queries through Application Insights Logs is a great way to understand the data and dependencies for an application. It is unrealistic however to expect everyone to understand and write Kusto queries.

## Dashboards

Dashboards are a feature of Azure Monitor that allow queries to be *pinned* to a common area where they can easily be viewed. They can also be shared to other team members or groups so they are able re-use the dashboard.

To create a dashboard, navigate to Application Insights Logs and enter one of the queries we created in the previous section, for example:

```
requests
| where name =='ContosoOrder'
| extend ProductName = customDimensions.ProductName
| extend Quantity = customDimensions.Quantity
| summarize Count=sum(toint(Quantity)) by tostring(ProductName)
| render piechart 
```

We can then go to the *Pin to* option on the top right, and pin to a Dashboard:

![Pin to Dashboard](<../images/Application Insights - Pin to Dashboard.png>)

Here we have an option to create a new dashboard, or add to an existing one. We can also create a private or shared dashboard.

Create a private dashboard, and pin your query to it. Navigate to the *Dashboards* section of the Azure Portal and select the dashboard just created. You may need to *Browse all dashboards* to see your dashboard. Once visible, the dashboard can be edited where items can be resized, moved around or other visual elements added. Here is an example with two pie charts added using the queries we have been using:

![Dashboard](<../images/Application Insights - Dashboards.png>)

## Workbooks

While dashboards are very useful to display and share visuals, Workbooks allow *custom* visuals to be created. For example, a custom visual could be created allowing a support team to search based on business data such as an *order id* to show an internal view of progress for a given order.

To create a workbook, navigate to Application Insights, and click the *Workbooks* option in the left hand pane (under *Monitoring*).

We will create a Workbook that allows a support team to search on the *order id* we have written to Application Insights from our Azure Function. We will then allow the user to select a given row of data in the response that will drill down and provide more details.

### Adding a Custom Search Field
To add a custom *Order Id* field, add an *Order Id* parameter and press *Save*, as follows:

![Add Parameter](<../images/Workbooks - Add Parameter.png>)

### Creating a Query Visual
When a workbook is created, a default *Query* visual is created, which allows a Kusto query to be applied to the visual. Edit the query and use the query below:

```
requests
| where name =='ContosoOrder'
| extend orderId= customDimensions.OrderId
| extend ProductName = customDimensions.ProductName
| join kind=leftouter (
    requests
    | where name == 'FulfilmentService'
    | extend orderCompleted=timestamp
  ) on operation_Id
| extend orderSearch = case(
    '{OrderID}' <> '', orderId,
    ''
)
| where orderSearch == '{OrderID}'
| project ProductName,orderId,name, orderReceived=timestamp, orderCompleted, operation_Id
| order by orderReceived desc
```

The above query uses the *OrderID* field as a parameter, represented in curly braces. Test the visual by entering an Order Id into the Order Id field. The visual should filter just on that Order id.

### Drill Down
Next, if one of the rows is clicked, we would like to drill down from the high level view to a lower level view to see more details. To do this, we need to *export* a parameter, in this case operation_Id, so we can include it in the *where* clause of the drill down query.

Edit the first visual (the one that gives the summary) and click *Advanced Settings*. Tick *When items are selected , export parameters*. Add a new parameter called *operation_Id* and make the exported name the same. Save the visual.

![Export Parameters](<../images/Workbooks - Export Parameters.png>)

Add another Query Visual and add the following query:

```
requests
| where operation_Id == '{operation_Id}'
| project timestamp, name, duration, success, resultCode
| order by timestamp desc 
```

As you can see, we are using the *operation_Id* parameter. Save the query, then when the top query is clicked, it should drill down in the second query, as follows:

![Drilldown](<../images/Workbooks Drilldown.png>)

Experiment with different queries and adding more visuals.