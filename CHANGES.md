# NokogiriReader should not fail silently

The `MARC::NokogiriReader` class does not override `#error(String)` from its parent class, which appears to be a no-op: https://github.com/sparklemotion/nokogiri/blob/master/lib/nokogiri/xml/sax/document.rb#L153

`ruby-marc` now overrides that method so it throws a StandardException if the XML parser encounters any error condition.


```ruby
def error(msg)
    raise(StandardError, "Error reading XML document: #{msg}")
end
```
