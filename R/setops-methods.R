### =========================================================================
### Set operations
### -------------------------------------------------------------------------

### TODO: What's the impact of circularity on the set operations?

setMethod("union", c("GRanges", "GRanges"),
    function(x, y, ignore.strand = FALSE, ...)
    {
        values(x) <- values(y) <- NULL  # so we can do 'c(x, y)' below
        reduce(c(x, y), drop.empty.ranges=TRUE, ignore.strand = ignore.strand)
    }
)

setMethod("intersect", c("GRanges", "GRanges"),
    function(x, y, ignore.strand = FALSE, ...)
    {
        values(x) <- values(y) <- NULL
        seqinfo(x) <- merge(seqinfo(x), seqinfo(y))
        ## If merge() is going to issue a warning, we don't want to get
        ## it twice.
        seqinfo(y) <- suppressWarnings(merge(seqinfo(y), seqinfo(x)))
        seqlengths <- seqlengths(x)
        ## If the length of a sequence is unknown (NA), then we use
        ## the max end value found on that sequence in 'x' or 'y'.
        seqlengths[is.na(seqlengths)] <-
            maxEndPerGRangesSequence(c(x, y))[is.na(seqlengths)]
        setdiff(x, gaps(y, end = seqlengths), ignore.strand = ignore.strand)
    }
)

setMethod("setdiff", c("GRanges", "GRanges"),
    function(x, y, ignore.strand = FALSE, ...)
    {
        values(x) <- values(y) <- NULL
        seqinfo(x) <- merge(seqinfo(x), seqinfo(y))
        ## If merge() is going to issue a warning, we don't want to get
        ## it twice.
        seqinfo(y) <- suppressWarnings(merge(seqinfo(y), seqinfo(x)))
        seqlengths <- seqlengths(x)
        ## If the length of a sequence is unknown (NA), then we use
        ## the max end value found on that sequence in 'x' or 'y'.
        seqlengths[is.na(seqlengths)] <-
            maxEndPerGRangesSequence(c(x, y))[is.na(seqlengths)]
        gaps(union(gaps(x, end = seqlengths), y, ignore.strand = ignore.strand),
            end = seqlengths)
    }
)


### =========================================================================
### Parallel set operations
### -------------------------------------------------------------------------

### FIXME: Why aren't all the parallel set operations using the same code
### for checking strand compatibility? E.g. "pintersect" and "psetdiff" use
### compatibleStrand() for this but not "punion".

setMethod("punion", c("GRanges", "GRanges"),
    function(x, y, fill.gap = FALSE, ignore.strand = FALSE, ...)
    {
        values(x) <- NULL
        seqinfo(x) <- merge(seqinfo(x), seqinfo(y))
        if (length(x) != length(y)) 
            stop("'x' and 'y' must have the same length")
        if (ignore.strand) 
           strand(y) <- strand(x) 
        if (!all((seqnames(x) == seqnames(y)) & (strand(x) == strand(y))))
                stop("'x' and 'y' elements must have compatible 'seqnames' ",
            "and 'strand' values")
        ranges(x) <- punion(ranges(x), ranges(y), fill.gap = fill.gap)
        x
    }
)

### FIXME: This is currently not doing a "punion" at all. It just appends
### the ranges in 'y' to their corresponding element in 'x'.
### 2 proposals for a more punion-like semantic:
###   (a) for (i in seq_len(length(x)))
###         x[[i]] <- punion(x[[i]], y[rep.int(i, length(x[[i]]))])
###   (b) for (i in seq_len(length(x)))
###         x[[i]] <- union(x[[i]], y[i])
### Note that behaviour (b) could also be considered a valid candidate for
### a union,GRangesList,GRanges method (which we don't have at the moment).
setMethod("punion", c("GRangesList", "GRanges"),
    function(x, y, fill.gap = FALSE, ...)
    {
        n <- length(x)
        if (n != length(y)) 
            stop("'x' and 'y' must have the same length")
        elementMetadata(x@unlistData) <- NULL
        elementMetadata(y) <- NULL
        ans <-
          split(c(x@unlistData, y), 
                c(Rle(seq_len(n), elementLengths(x)), Rle(seq_len(n))))
        names(ans) <- names(x)
        ans
    }
)

setMethod("punion", c("GRanges", "GRangesList"),
    function(x, y, fill.gap = FALSE, ...)
    {
        callGeneric(y, x)
    }
)

setMethod("pintersect", c("GRanges", "GRanges"),
    function(x, y, resolve.empty = c("none", "max.start", "start.x"),
        ignore.strand = FALSE, ...)
    {
        resolve.empty <- match.arg(resolve.empty)
        values(x) <- NULL
        seqinfo(x) <- merge(seqinfo(x), seqinfo(y))
        if (length(x) != length(y)) 
            stop("'x' and 'y' must have the same length")
        if(ignore.strand)
            strand(y) <- strand(x)
        if (!all((seqnames(x) == seqnames(y)) &
                  compatibleStrand(strand(x), strand(y))))
            stop("'x' and 'y' elements must have compatible 'seqnames' ",
                 "and 'strand' values")
        ## Update the ranges.
        ranges(x) <- pintersect(ranges(x), ranges(y),
                                resolve.empty = resolve.empty)
        ## Update the strand.
        ansStrand <- strand(x)
        resolveStrand <- as(ansStrand == "*", "IRanges")
        if (length(resolveStrand) > 0)
            ansStrand[as.integer(resolveStrand)] <-
              seqselect(strand(y), resolveStrand)
        strand(x) <- ansStrand
        x
    }
)

### TODO: Like for "punion", the semantic of the
### pintersect,GRangesList,GRanges method should simply derive from
### the semantic of the pintersect,GRanges,GRanges. Then the
### implementation and documentation will be both much easier to understand.
### It's hard to guess what's the current semantic of this method is by
### just looking at the code below, but it doesn't seem to be one of:
###   (a) for (i in seq_len(length(x)))
###         x[[i]] <- pintersect(x[[i]], y[rep.int(i, length(x[[i]]))])
###   (b) for (i in seq_len(length(x)))
###         x[[i]] <- intersect(x[[i]], y[i])
### It seems to be close to (b) but with special treatment of the "*"
### strand value in 'y'.
### FIXME: 'resolve.empty' is silently ignored.
setMethod("pintersect", c("GRangesList", "GRanges"),
    function(x, y, resolve.empty = c("none", "max.start", "start.x"), ...)
    {
        ## TODO: Use "seqinfo<-" method for GRangesList objects when it
        ## becomes available.
        seqinfo(x@unlistData) <- merge(seqinfo(x), seqinfo(y))
        if (length(x) != length(y)) 
            stop("'x' and 'y' must have the same length")
        ok <- (seqnames(x@unlistData) == rep(seqnames(y), elementLengths(x))) &
              compatibleStrand(strand(x@unlistData),
                               rep(strand(y), elementLengths(x)))
        ok <-
          new2("CompressedLogicalList", unlistData = as.vector(ok),
               partitioning = x@partitioning)
        if (ncol(elementMetadata(x@unlistData)) > 0)
            elementMetadata(x@unlistData) <- NULL
        if (ncol(elementMetadata(y)) > 0)
            elementMetadata(y) <- NULL
        x <- x[ok]
        y <- rep(y, sum(ok))
        x@unlistData@ranges <-
          pintersect(x@unlistData@ranges, y@ranges, resolve.empty = "start.x")
        x[width(x) > 0L]
    }
)

setMethod("pintersect", c("GRanges", "GRangesList"),
    function(x, y, resolve.empty = c("none", "max.start", "start.x"), ...)
    {
        callGeneric(y, x)
    }
)

### TODO: Revisit this method (seems to do strange things).
setMethod("pintersect", c("GappedAlignments", "GRanges"),
    function(x, y, ...)
    {
        bounds <- try(callGeneric(granges(x), y), silent = TRUE)
        if (inherits(bounds, "try-error"))
            stop("CIGAR is empty after intersection")
        start <- start(bounds) - start(x) + 1L
        start[which(start < 1L)] <- 1L
        end <- end(bounds) - end(x) - 1L
        end[which(end > -1L)] <- -1L
        narrow(x, start=start, end=end)
    }
)

setMethod("pintersect", c("GRanges", "GappedAlignments"),
    function(x, y, ...)
    {
        callGeneric(y, x)
    }
)

setMethod("psetdiff", c("GRanges", "GRanges"),
    function(x, y, ignore.strand = FALSE, ...)
    {
        values(x) <- NULL
        seqinfo(x) <- merge(seqinfo(x), seqinfo(y))
        if (length(x) != length(y)) 
            stop("'x' and 'y' must have the same length")
        if(ignore.strand)
            strand(y) <- strand(x)
        ok <- (seqnames(x) == seqnames(y)) &
              compatibleStrand(strand(x), strand(y))
        ## Update the ranges.
        ansRanges <- ranges(x)
        seqselect(ansRanges, ok) <-
          callGeneric(seqselect(ranges(x), ok), seqselect(ranges(y), ok))
        ranges(x) <- ansRanges
        ## Update the strand.
        ansStrand <- strand(x)
        resolveStrand <- as(ansStrand == "*", "IRanges")
        if (length(resolveStrand) > 0)
            ansStrand[as.integer(resolveStrand)] <-
              seqselect(strand(y), resolveStrand)
        strand(x) <- ansStrand
        x
    }
)

### TODO: Review the semantic of this method (see previous TODO's for
### "punion" and "pintersect" methods for GRanges,GRangesList).
setMethod("psetdiff", c("GRanges", "GRangesList"),
    function(x, y, ...)
    {
        ansSeqinfo <- merge(seqinfo(x), seqinfo(y))
        if (length(x) != length(y)) 
            stop("'x' and 'y' must have the same length")
        ok <- (rep(seqnames(x), elementLengths(y)) == seqnames(y@unlistData)) &
              compatibleStrand(rep(strand(x), elementLengths(y)),
                               strand(y@unlistData))
        if (!all(ok)) {
            ok <-
              new2("CompressedLogicalList", unlistData = as.vector(ok),
                   partitioning = y@partitioning)
            y <- y[ok]
        }
        ansRanges <- gaps(ranges(y), start = start(x), end = end(x))
        ansSeqnames <- rep(seqnames(x), elementLengths(ansRanges))
        ansStrand <- rep(strand(x), elementLengths(ansRanges))
        ansGRanges <-
          GRanges(ansSeqnames, unlist(ansRanges, use.names = FALSE), ansStrand)
        seqinfo(ansGRanges) <- ansSeqinfo
        new2("GRangesList",
             elementMetadata = new("DataFrame", nrows = length(x)),
             unlistData = ansGRanges, partitioning = ansRanges@partitioning,
             check=FALSE)
    }
)

### Equivalent to 'mendoapply(setdiff, x, y)'.
setMethod("psetdiff", c("GRangesList", "GRangesList"),
    function(x, y, ...)
    {
        if (length(x) != length(y))
            stop("'x' and 'y' must have the same length")
        seqinfo(x) <- merge(seqinfo(x), seqinfo(y))
        seqlevels(y) <- seqlevels(x)
        xgr <- deconstructGRLintoGR(x)
        ygr <- deconstructGRLintoGR(y)
        gr <- setdiff(xgr, ygr, ...)
        reconstructGRLfromGR(gr, x)
    }
)
